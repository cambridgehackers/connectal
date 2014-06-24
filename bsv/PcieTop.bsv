// Copyright (c) 2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Vector            :: *;
import Clocks            :: *;
import GetPut            :: *;
import FIFO              :: *;
import Connectable       :: *;
import ClientServer      :: *;
import Xilinx            :: *;
import DefaultValue      :: *;
import PcieSplitter      :: *;
import PcieTracer        :: *;
import PcieGearbox       :: *;
import XbsvXilinx7Pcie   :: *;
import PCIEWRAPPER       :: *;
import Portal            :: *;
import Leds              :: *;
import Top               :: *;
import MemSlaveEngine    :: *;
import MemMasterEngine   :: *;
import PcieCsr           :: *;
import MemSlave          :: *;
import MemTypes          :: *;

`ifndef DataBusWidth
`define DataBusWidth 64
`endif
`ifndef NumberOfMasters
`define NumberOfMasters 1
`endif
`ifndef PinType
`define PinType Empty
`endif
`ifdef USES_FCLK1
`define CLOCK_ARG  defaultClock
`else
`define CLOCK_ARG
`endif

typedef `DataBusWidth DataBusWidth;
typedef `NumberOfMasters NumberOfMasters;
typedef `PinType PinType;

interface PcieTop#(type ipins);
   (* prefix="PCIE" *)
   interface PciewrapPci_exp#(PcieLanes) pcie;
   (* always_ready *)
   method Bit#(NumLeds) leds();
   (* prefix="" *)
   interface ipins       pins;
endinterface

interface PcieHost#(numeric type dsz, numeric type nSlaves);
   interface Vector#(16,MSIX_Entry)              msixEntry;
   interface MemMaster#(32,32)                   master;
   interface Vector#(nSlaves,MemSlave#(40,dsz))  slave;
   interface Put#(Tuple2#(Bit#(64),Bit#(32)))    interruptRequest;
   interface Client#(TLPData#(16), TLPData#(16)) pci;
endinterface

(* synthesize *)
module [Module] mkPcieHost#(PciId my_pciId)(PcieHost#(DataBusWidth, NumberOfMasters));
// provisos(
//    Mul#(TDiv#(dsz, 8), 8, dsz),
//     Add#(a__, TDiv#(dsz, 32), 8),
//     Add#(b__, TMul#(32, TDiv#(dsz, 32)), 256),
//     Add#(c__, TMul#(8, TDiv#(dsz, 32)), 64),
//     Add#(d__, dsz, 256),
//     Add#(e__, 32, dsz),
//     Mul#(TDiv#(dsz, 32), 32, dsz));
   Clock epClock125 <- exposeCurrentClock();
   Reset epReset125 <- exposeCurrentReset();
   let dispatcher <- mkTLPDispatcher;
   let arbiter    <- mkTLPArbiter;
   Vector#(NumberOfMasters,MemSlaveEngine#(DataBusWidth)) sEngine <- replicateM(mkMemSlaveEngine(my_pciId));
   Vector#(NumberOfMasters,MemSlave#(40,DataBusWidth)) slavearr;
   MemInterrupt intr <- mkMemInterrupt(my_pciId);

   Vector#(PortMax, MemMasterEngine) mvec;
   for (Integer i = 0; i < valueOf(PortMax) - 1 + valueOf(NumberOfMasters); i=i+1) begin
       let tlp;
       if (i == portInterrupt)
           tlp = intr.tlp;
       else if (i >= portAxi) begin
           tlp = sEngine[i - portAxi].tlp;
           slavearr[i - portAxi] = sEngine[i - portAxi].slave;
       end
       else begin
           mvec[i] <- mkMemMasterEngine(my_pciId);
           tlp = mvec[i].tlp;
       end
       mkConnection((interface Server;
                        interface response = dispatcher.out[i];
                        interface request = arbiter.in[i];
                     endinterface), tlp);
   end

   PcieTracer  traceif <- mkPcieTracer();
   mkConnection(traceif.bus, (interface Client;
                                 interface request = arbiter.outToBus;
                                 interface response = dispatcher.inFromBus;
                              endinterface));

   PcieControlAndStatusRegs csr <- mkPcieControlAndStatusRegs(traceif.tlpdata);
   MemSlave#(32,32) my_slave <- mkMemSlave(csr.client);
   mkConnection(mvec[portConfig].master, my_slave);

   interface msixEntry = csr.msixEntry;
   interface master = mvec[portPortal].master;
   interface slave = slavearr;
   interface interruptRequest = intr.interruptRequest;
   interface pci = traceif.pci;
endmodule: mkPcieHost

(* synthesize *)
module mkSynthesizeablePortalTop(PortalTop#(40, DataBusWidth, PinType, NumberOfMasters));
   Clock defaultClock <- exposeCurrentClock();
   let top <- mkPortalTop(`CLOCK_ARG);
   interface masters = top.masters;
   interface slave = top.slave;
   interface interrupt = top.interrupt;
   interface leds = top.leds;
   interface pins = top.pins;
endmodule

(* no_default_clock, no_default_reset *)
module mkPcieTop #(Clock pci_sys_clk_p, Clock pci_sys_clk_n, Clock sys_clk_p, Clock sys_clk_n, Reset pci_sys_reset_n)
   (PcieTop#(PinType));

   Clock sys_clk_200mhz <- mkClockIBUFDS(sys_clk_p, sys_clk_n);
   Clock sys_clk_200mhz_buf <- mkClockBUFG(clocked_by sys_clk_200mhz);
   Clock pci_clk_100mhz_buf <- mkClockIBUFDS_GTE2(True, pci_sys_clk_p, pci_sys_clk_n);

   // Instantiate the PCIE endpoint
   PCIExpressX7#(PcieLanes) ep7 <- mkPCIExpressEndpointX7( clocked_by pci_clk_100mhz_buf
							  , reset_by pci_sys_reset_n
							  );
   // The PCIe endpoint exports full (250MHz) and half-speed (125MHz) clocks
   Clock epClock250 = ep7.user.clk_out;
   Reset user_reset_n <- mkResetInverter(ep7.user.reset_out, clocked_by epClock250);
   Reset epReset250 <- mkAsyncReset(4, user_reset_n, epClock250);

   ClockGenerator7Params     params = defaultValue;
   params.clkin1_period    = 4.000;
   params.clkin_buffer     = False;
   params.clkfbout_mult_f  = 4.000;
   params.clkout0_divide_f = 8.000;
   ClockGenerator7           clkgen <- mkClockGenerator7(params, clocked_by epClock250, reset_by user_reset_n);
   Clock epClock125 = clkgen.clkout0; /* half speed user_clk */
   Reset epReset125 <- mkAsyncReset(4, user_reset_n, epClock125);

   let portalTop <- mkSynthesizeablePortalTop(clocked_by epClock125, reset_by epReset125);
   PcieHost#(DataBusWidth, NumberOfMasters) pciehost <- mkPcieHost(
         PciId{ bus:  ep7.cfg.bus_number(), dev: ep7.cfg.device_number(), func: ep7.cfg.function_number()},
         clocked_by epClock125, reset_by epReset125);

   // The PCIE endpoint is processing TLPData#(8)s at 250MHz.  The
   // AXI bridge is accepting TLPData#(16)s at 125 MHz. The
   // connection between the endpoint and the AXI contains GearBox
   // instances for the TLPData#(8)@250 <--> TLPData#(16)@125
   // conversion.
   PcieGearbox gb <- mkPcieGearbox(epClock250, epReset250, epClock125, epReset125);
   mkConnection(ep7.tlp, gb.tlp, clocked_by epClock250, reset_by epReset250);
   mkConnection(gb.pci, pciehost.pci, clocked_by epClock125, reset_by epReset125);

   mkConnection(pciehost.master, portalTop.slave, clocked_by epClock125, reset_by epReset125);
   if (valueOf(NumberOfMasters) > 0) begin
      mapM(uncurry(mkConnection),zip(portalTop.masters, pciehost.slave));
   end

   // going from level to edge-triggered interrupt
   Vector#(15, Reg#(Bool)) interruptRequested <- replicateM(mkReg(False, clocked_by epClock125, reset_by epReset125));
   rule interrupt_rule;
     Integer intr_num = 0;
     for (Integer i = 0; i < 15; i = i + 1) begin
	 if (intr_num == 0 && portalTop.interrupt[i] && !interruptRequested[i])
             intr_num = i+1;
	 interruptRequested[i] <= portalTop.interrupt[i];
     end
     if (intr_num != 0) begin // i= 0 for the directory
        MSIX_Entry msixEntry = pciehost.msixEntry[intr_num];
        pciehost.interruptRequest.put(tuple2({msixEntry.addr_hi, msixEntry.addr_lo}, msixEntry.msg_data));
     end
   endrule

   interface pcie = ep7.pcie;
   method Bit#(NumLeds) leds();
      return extend({ep7.user.lnk_up(),3'd2});
   endmethod
   interface pins = portalTop.pins;
endmodule: mkPcieTop
