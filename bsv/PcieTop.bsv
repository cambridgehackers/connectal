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
import Clocks          :: *;
import GetPut            :: *;
import FIFO              :: *;
import FIFOF        :: *;
import Connectable       :: *;
import ClientServer      :: *;
import Xilinx            :: *;
import DefaultValue    :: *;
import PcieSplitter      :: *;
import PcieGearbox    :: *;
import XbsvXilinx7Pcie   :: *;
import PCIEWRAPPER       :: *;
import Portal            :: *;
import Leds              :: *;
import Top               :: *;
import AxiSlaveEngine    :: *;
import AxiMasterEngine   :: *;
import AxiMasterSlave    :: *;
import AxiDma            :: *;
import AxiCsr            :: *;

import BRAM         :: *;
//import BRAMFIFO     :: *;

typedef (function Module#(PortalTop#(40, dsz, ipins,nMasters)) mkPortalTop()) MkPortalTop#(numeric type dsz, type ipins, numeric type nMasters);

`ifdef Artix7
typedef 4 PcieLanes;
typedef 4 NumLeds;
`else
typedef 8 PcieLanes;
typedef 8 NumLeds;
`endif

interface PcieTop#(type ipins);
   (* prefix="PCIE" *)
   interface PciewrapPci_exp#(PcieLanes) pcie;
   (* always_ready *)
   method Bit#(NumLeds) leds();
   interface ipins       pins;
endinterface

// The top-level interface of the PCIe-to-AXI bridge
interface PcieSplitter;
   interface Client#(TLPData#(16), TLPData#(16)) pci;
   interface Put#(TimestampedTlpData) trace;
   interface Vector#(16,MSIX_Entry) msixEntry;
endinterface: PcieSplitter

// The PCIe-to-AXI bridge puts all of the elements together
module mkPcieSplitter#(TLPDispatcher dispatcher, TLPArbiter arbiter, AxiControlAndStatusRegs csr)(PcieSplitter);

   Reg#(Bit#(32)) timestamp <- mkReg(0);
   rule incTimestamp;
       timestamp <= timestamp + 1;
   endrule
//   rule endTrace if (csr.tlpTracing && csr.tlpTraceLimit != 0 && csr.tlpTraceBramWrAddr > truncate(csr.tlpTraceLimit));
//       csr.tlpTracing <= False;
//   endrule

   FIFO#(TLPData#(16)) tlpFromBusFifo <- mkFIFO();
   Reg#(Bool) skippingIncomingTlps <- mkReg(False);
   PulseWire fromPcie <- mkPulseWire;
   PulseWire   toPcie <- mkPulseWire;
   Wire#(TLPData#(16)) fromPcieTlp <- mkDWire(unpack(0));
   Wire#(TLPData#(16))   toPcieTlp <- mkDWire(unpack(0));
   rule traceTlpFromBus;
       let tlp = tlpFromBusFifo.first;
       tlpFromBusFifo.deq();
       dispatcher.inFromBus.put(tlp);
       $display("tlp in: %h\n", tlp);
       if (csr.tlpTracing) begin
           TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
           // skip root_broadcast_messages sent to tlp.hit 0                                                                                                  
           if (tlp.sof && tlp.hit == 0 && hdr_3dw.pkttype != COMPLETION) begin
 	      skippingIncomingTlps <= True;
	   end
	   else if (skippingIncomingTlps && !tlp.sof) begin
	      // do nothing
	   end
	   else begin
	      fromPcie.send();
	      fromPcieTlp <= tlp;
	       skippingIncomingTlps <= False;
	   end
       end
   endrule: traceTlpFromBus

   FIFO#(TLPData#(16)) tlpToBusFifo <- mkFIFO();
   rule traceTlpToBus;
       let tlp <- arbiter.outToBus.get();
       tlpToBusFifo.enq(tlp);
       if (csr.tlpTracing) begin
	  toPcie.send();
	  toPcieTlp <= tlp;
       end
   endrule: traceTlpToBus

   rule doTracing if (fromPcie || toPcie);
      TimestampedTlpData fromttd = fromPcie ? TimestampedTlpData { timestamp: timestamp, source: 7'h04, tlp: fromPcieTlp } : unpack(0);
      csr.fromPcieTraceBramPort.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: truncate(csr.fromPcieTraceBramWrAddr), datain: fromttd });
      csr.fromPcieTraceBramWrAddr <= csr.fromPcieTraceBramWrAddr + 1;

      TimestampedTlpData   tottd = toPcie ? TimestampedTlpData { timestamp: timestamp, source: 7'h08, tlp: toPcieTlp } : unpack(0);
      csr.toPcieTraceBramPort.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: truncate(csr.toPcieTraceBramWrAddr), datain: tottd });
      csr.toPcieTraceBramWrAddr <= csr.toPcieTraceBramWrAddr + 1;
   endrule

   interface Client    pci;
      interface request = toGet(tlpToBusFifo);
      interface response = toPut(tlpFromBusFifo);
   endinterface
/*
   interface Server    axi;
      interface response = dispatcher.outToAxi;
      interface request = arbiter.inFromAxi;
   endinterface
*/
   interface Put trace;
       method Action put(TimestampedTlpData ttd);
	   if (csr.tlpTracing) begin
	       ttd.timestamp = timestamp;
	       csr.toPcieTraceBramPort.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: truncate(csr.toPcieTraceBramWrAddr), datain: ttd });
	       csr.toPcieTraceBramWrAddr <= csr.toPcieTraceBramWrAddr + 1;
	   end
       endmethod
   endinterface: trace

   // method Action interrupt();
   //     portalEngine.interruptRequested <= True;
   // endmethod
   interface Vector msixEntry = csr.msixEntry;
endmodule: mkPcieSplitter

(* no_default_clock, no_default_reset *)
module [Module] mkPcieTopFromPortal #(Clock pci_sys_clk_p, Clock pci_sys_clk_n,
				      Clock sys_clk_p,     Clock sys_clk_n,
				      Reset pci_sys_reset_n,
				      MkPortalTop#(dsz, ipins, nMasters) mkPortalTop)
   (PcieTop#(ipins))
   provisos (Mul#(TDiv#(dsz, 32), 32, dsz),
	     Add#(b__, 32, dsz),
	     Add#(c__, dsz, 256),
	     Add#(d__, TMul#(8, TDiv#(dsz, 32)), 64),
	     Add#(e__, TMul#(32, TDiv#(dsz, 32)), 256),
	     Add#(f__, TDiv#(dsz, 32), 8),
	     Mul#(TDiv#(dsz, 8), 8, dsz),
	     Add#(g__, nMasters, 1)
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

   let my_pciId = PciId { bus:  _ep.cfg.bus_number(),
	 dev: _ep.cfg.device_number(), func: _ep.cfg.function_number()};

   MakeResetIfc portalResetIfc <- mkReset(10, False, epClock125, clocked_by epClock125, reset_by epReset125);
   TLPDispatcher        dispatcher <- mkTLPDispatcher(clocked_by epClock125, reset_by epReset125);
   TLPArbiter           arbiter    <- mkTLPArbiter(clocked_by epClock125, reset_by epReset125);
   AxiControlAndStatusRegs csr     <- mkAxiControlAndStatusRegs(portalResetIfc, clocked_by epClock125, reset_by epReset125);
   AxiMasterEngine splitMaster <- mkAxiMasterEngine(my_pciId, clocked_by epClock125, reset_by epReset125);
   mkConnection(splitMaster.master, csr.slave, clocked_by epClock125, reset_by epReset125);
   mkConnection(dispatcher.outToConfig, splitMaster.tlp.response, clocked_by epClock125, reset_by epReset125);
   mkConnection(splitMaster.tlp.request, arbiter.inFromConfig, clocked_by epClock125, reset_by epReset125);

   PcieSplitter  bridge <- mkPcieSplitter(dispatcher, arbiter, csr, clocked_by epClock125, reset_by epReset125);

   // The PCIE endpoint is processing TLPWord#(8)s at 250MHz.  The
   // AXI bridge is accepting TLPWord#(16)s at 125 MHz. The
   // connection between the endpoint and the AXI contains GearBox
   // instances for the TLPWord#(8)@250 <--> TLPWord#(16)@125
   // conversion.
   PcieGearbox gb <- mkPcieGearbox(epClock250, epReset250, epClock125, epReset125);
   mkConnection(gb.tlp, _ep.tlp, clocked_by epClock250, reset_by epReset250);
   mkConnection(gb.pci, bridge.pci, clocked_by epClock125, reset_by epReset125);
   
   // instantiate user portals
   let portalTop <- mkPortalTop(clocked_by epClock125, reset_by portalResetIfc.new_rst);
   AxiSlaveEngine#(dsz) axiSlaveEngine <- mkAxiSlaveEngine(my_pciId, clocked_by epClock125, reset_by epReset125);
   AxiMasterEngine axiMasterEngine <- mkAxiMasterEngine(my_pciId, clocked_by epClock125, reset_by epReset125);

   // Build the PCIe-to-AXI bridge
   mkConnection(
//bridge.axi
   (interface Server;
      interface response = dispatcher.outToAxi;
      interface request = arbiter.inFromAxi;
   endinterface)
, axiSlaveEngine.pci, clocked_by epClock125, reset_by epReset125);
   Vector#(nMasters,Axi3Master#(40,dsz,6)) m_axis;   
   if(valueOf(nMasters) > 0) begin
      m_axis[0] <- mkAxiDmaMaster(portalTop.masters[0],clocked_by epClock125, reset_by portalResetIfc.new_rst);
      mkConnection(m_axis[0], axiSlaveEngine.slave, clocked_by epClock125, reset_by epReset125);
   end

   mkConnection(
       (interface Server;
          interface response = dispatcher.outToPortal;
          interface request = arbiter.inFromPortal;
       endinterface),
       axiMasterEngine.tlp);

   Axi3Slave#(32,32,12) ctrl <- mkAxiDmaSlave(portalTop.slave, clocked_by epClock125, reset_by epReset125);
   mkConnection(axiMasterEngine.master, ctrl, clocked_by epClock125, reset_by epReset125);

   // going from level to edge-triggered interrupt
   Vector#(15, Reg#(Bool)) interruptRequested <- replicateM(mkReg(False, clocked_by epClock125, reset_by epReset125));
   for (Integer i = 0; i < 15; i = i + 1) begin
      // intr_num 0 for the directory
      Integer intr_num = i+1;
      MSIX_Entry msixEntry = bridge.msixEntry[intr_num];
      rule interruptRequest;
	 if (portalTop.interrupt[i] && !interruptRequested[i])
	    axiMasterEngine.interruptRequest.put(tuple2({msixEntry.addr_hi, msixEntry.addr_lo}, msixEntry.msg_data));
	 interruptRequested[i] <= portalTop.interrupt[i];
      endrule
   end

   interface pcie = _ep.pcie;
   method Bit#(NumLeds) leds();
      return extend({_ep.user.lnk_up(),3'd2});
   endmethod
   interface pins = portalTop.pins;

endmodule: mkPcieTopFromPortal

`ifndef DataBusWidth
`define DataBusWidth 64
`endif
`ifndef NumberOfMasters
`define NumberOfMasters 1
`endif
(* synthesize *)
module mkSynthesizeablePortalTop(PortalTop#(40, `DataBusWidth, Empty, `NumberOfMasters));
   let top <- mkPortalTop();
   interface masters = top.masters;
   interface slave = top.slave;
   interface interrupt = top.interrupt;
   interface leds = top.leds;
   interface pins = top.pins;
endmodule

`ifndef PinType
`define PinType Empty
`endif
module mkPcieTop #(Clock pci_sys_clk_p, Clock pci_sys_clk_n,
   Clock sys_clk_p,     Clock sys_clk_n,
   Reset pci_sys_reset_n)
   (PcieTop#(`PinType));
   let top <- mkPcieTopFromPortal(pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n,mkSynthesizeablePortalTop);
   return top;
endmodule: mkPcieTop
