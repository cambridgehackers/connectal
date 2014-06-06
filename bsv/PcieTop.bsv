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
import AxiSlaveEngine    :: *;
import MemMasterEngine   :: *;
import AxiMasterSlave    :: *;
import AxiDma            :: *;
import PcieCsr           :: *;
import MemSlave          :: *;
import Dma               :: *;

`ifdef Artix7
typedef 4 PcieLanes;
typedef 4 NumLeds;
`else
typedef 8 PcieLanes;
typedef 8 NumLeds;
`endif
`ifndef DataBusWidth
`define DataBusWidth 64
`endif
`ifndef NumberOfMasters
`define NumberOfMasters 1
`endif
`ifndef PinType
`define PinType Empty
`endif

typedef (function Module#(PortalTop#(40, dsz, ipins, `NumberOfMasters)) mkPortalTop()) MkPortalTop#(numeric type dsz, type ipins);

interface PcieTop#(type ipins);
   (* prefix="PCIE" *)
   interface PciewrapPci_exp#(PcieLanes) pcie;
   (* always_ready *)
   method Bit#(NumLeds) leds();
   interface ipins       pins;
endinterface

interface PcieHost#(numeric type dsz);
   interface Vector#(16,MSIX_Entry) msixEntry;
   interface MemMaster#(32,32) master;
   interface Axi3Slave#(40,dsz,6)  slave;
   interface Put#(Tuple2#(Bit#(64),Bit#(32))) interruptRequest;
endinterface

module [Module] mkPcieHost #(Clock epClock250, Reset epReset250, PciId my_pciId,
Server#(TLPData#(8), TLPData#(8)) ep_tlp)(PcieHost#(dsz))
provisos(
   Mul#(TDiv#(dsz, 8), 8, dsz),
    Add#(a__, TDiv#(dsz, 32), 8),
    Add#(b__, TMul#(32, TDiv#(dsz, 32)), 256),
    Add#(c__, TMul#(8, TDiv#(dsz, 32)), 64),
    Add#(d__, dsz, 256),
    Add#(e__, 32, dsz),
    Mul#(TDiv#(dsz, 32), 32, dsz));
   Clock epClock125 <- exposeCurrentClock();
   Reset epReset125 <- exposeCurrentReset();
   let dispatcher <- mkTLPDispatcher;
   let arbiter    <- mkTLPArbiter;
   AxiSlaveEngine#(dsz) sEngine <- mkAxiSlaveEngine(my_pciId);

   Vector#(PortMax, MemMasterEngine) mvec;
   for (Integer i = 0; i < valueOf(PortMax); i=i+1) begin
       let serv = (interface Server;
                     interface response = dispatcher.out[i];
                     interface request = arbiter.in[i];
                  endinterface);
       if (i == portAxi)
           mkConnection(serv, sEngine.tlp);
       else begin
           mvec[i] <- mkMemMasterEngine(my_pciId);
           mkConnection(serv, mvec[i].tlp);
       end
   end

   // The PCIE endpoint is processing TLPData#(8)s at 250MHz.  The
   // AXI bridge is accepting TLPData#(16)s at 125 MHz. The
   // connection between the endpoint and the AXI contains GearBox
   // instances for the TLPData#(8)@250 <--> TLPData#(16)@125
   // conversion.
   PcieGearbox gb <- mkPcieGearbox(epClock250, epReset250, epClock125, epReset125);
   mkConnection(ep_tlp, gb.tlp, clocked_by epClock250, reset_by epReset250);

   PcieTracer  traceif <- mkPcieTracer();
   mkConnection(gb.pci, traceif.pci);
   mkConnection(traceif.bus, (interface Client;
                                 interface request = arbiter.outToBus;
                                 interface response = dispatcher.inFromBus;
                              endinterface));

   PcieControlAndStatusRegs csr <- mkPcieControlAndStatusRegs(traceif.tlpdata);
   MemSlave#(32,32) my_slave <- mkMemSlave(csr.client);
   mkConnection(mvec[portConfig].master, my_slave);

   interface msixEntry = csr.msixEntry;
   interface master = mvec[portPortal].master;
   interface slave = sEngine.slave;
   interface interruptRequest = mvec[portPortal].interruptRequest;
endmodule: mkPcieHost

(* no_default_clock, no_default_reset *)
module [Module] mkPcieTopFromPortal #(Clock pci_sys_clk_p, Clock pci_sys_clk_n, Clock sys_clk_p, Clock sys_clk_n, Reset pci_sys_reset_n,
				      MkPortalTop#(dsz, ipins) mkPortalTop)
   (PcieTop#(ipins))
   provisos (Mul#(TDiv#(dsz, 32), 32, dsz),
	     Add#(b__, 32, dsz),
	     Add#(c__, dsz, 256),
	     Add#(d__, TMul#(8, TDiv#(dsz, 32)), 64),
	     Add#(e__, TMul#(32, TDiv#(dsz, 32)), 256),
	     Add#(f__, TDiv#(dsz, 32), 8),
	     Mul#(TDiv#(dsz, 8), 8, dsz)
      );

   Clock sys_clk_200mhz <- mkClockIBUFDS(sys_clk_p, sys_clk_n);
   Clock sys_clk_200mhz_buf <- mkClockBUFG(clocked_by sys_clk_200mhz);
   Clock pci_clk_100mhz_buf <- mkClockIBUFDS_GTE2(True, pci_sys_clk_p, pci_sys_clk_n);

   // Instantiate the PCIE endpoint
   PCIExpressX7#(PcieLanes) _ep <- mkPCIExpressEndpointX7( defaultValue
						  , clocked_by pci_clk_100mhz_buf
						  , reset_by pci_sys_reset_n
						  );
   // The PCIe endpoint exports full (250MHz) and half-speed (125MHz) clocks
   Clock epClock250 = _ep.user.clk_out;
   Reset user_reset_n <- mkResetInverter(_ep.user.reset_out);
   Reset epReset250 <- mkAsyncReset(4, user_reset_n, epClock250);

   ClockGenerator7Params     params = defaultValue;
   params.clkin1_period    = 4.000;
   params.clkin_buffer     = False;
   params.clkfbout_mult_f  = 4.000;
   params.clkout0_divide_f = 8.000;
   ClockGenerator7           clkgen <- mkClockGenerator7(params, clocked_by _ep.user.clk_out, reset_by user_reset_n);
   Clock epClock125 = clkgen.clkout0; /* half speed user_clk */
   Reset epReset125 <- mkAsyncReset(4, user_reset_n, epClock125);

   let portalTop <- mkPortalTop(clocked_by epClock125, reset_by epReset125);
   PcieHost#(dsz) pciehost <- mkPcieHost(epClock250, epReset250,
         PciId{ bus:  _ep.cfg.bus_number(), dev: _ep.cfg.device_number(), func: _ep.cfg.function_number()},
         _ep.tlp, clocked_by epClock125, reset_by epReset125);

   mkConnection(pciehost.master, portalTop.slave, clocked_by epClock125, reset_by epReset125);
   if (`NumberOfMasters > 0) begin
      Vector#(`NumberOfMasters,Axi3Master#(40,dsz,6)) m_axis;   
      m_axis[0] <- mkAxiDmaMaster(portalTop.masters[0], clocked_by epClock125, reset_by epReset125);
      mkConnection(m_axis[0], pciehost.slave, clocked_by epClock125, reset_by epReset125);
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

   interface pcie = _ep.pcie;
   method Bit#(NumLeds) leds();
      return extend({_ep.user.lnk_up(),3'd2});
   endmethod
   interface pins = portalTop.pins;
endmodule: mkPcieTopFromPortal

(* synthesize *)
module mkSynthesizeablePortalTop(PortalTop#(40, `DataBusWidth, Empty, `NumberOfMasters));
   let top <- mkPortalTop();
   interface masters = top.masters;
   interface slave = top.slave;
   interface interrupt = top.interrupt;
   interface leds = top.leds;
   interface pins = top.pins;
endmodule

module mkPcieTop #(Clock pci_sys_clk_p, Clock pci_sys_clk_n, Clock sys_clk_p, Clock sys_clk_n, Reset pci_sys_reset_n)
   (PcieTop#(`PinType));
   let top <- mkPcieTopFromPortal(pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n,mkSynthesizeablePortalTop);
   return top;
endmodule: mkPcieTop
