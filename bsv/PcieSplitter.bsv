
// Copyright (c) 2008- 2009 Bluespec, Inc.  All rights reserved.
// $Revision$
// $Date$
// Copyright (c) 2013 Quanta Research Cambridge, Inc.

// PCI-Express for Xilinx 7
// FPGAs.

package PcieSplitter;

// This is a package which acts as a bridge between a TLP-based PCIe
// interface on one side and an AXI slave (portal) and AXI Master on
// the other.

import GetPut       :: *;
import Connectable  :: *;
import Vector       :: *;
import FIFO         :: *;
import FIFOF        :: *;
import Counter      :: *;
import DefaultValue :: *;
import BRAM         :: *;
import BRAMFIFO     :: *;
import ConfigReg    :: *;
import PCIE         :: *;
import DReg         :: *;
import Clocks       :: *;

import ByteBuffer    :: *;
import ByteCompactor :: *;

import DefaultValue         :: *;
import BUtils               :: *;
import ClientServer         :: *;
import Memory               :: *;
import Portal               :: *;
import AxiMasterEngine      :: *;
import AxiCsr               :: *;

interface PcieBridge;
   interface GetPut#(TLPData#(16)) master; // to the portal dma
   interface GetPut#(TLPData#(16)) slave;  // to the portal control
   interface Put#(TimestampedTlpData) trace;
   interface Reset portalReset;
endinterface

// The top-level interface of the PCIe-to-AXI bridge
interface PcieSplitter#(numeric type bpb);
   interface Get#(TLPData#(16)) toPciGet;
   interface Put#(TLPData#(16)) fromPciPut;
   //interface GetPut#(TLPData#(16)) csr; // to csr
   interface PcieBridge brif;
   //interface GetPut#(TLPData#(16)) master; // to the portal control
   //interface GetPut#(TLPData#(16)) slave;  // to the portal DMA
   //interface Reset portalReset;
   //interface Put#(TimestampedTlpData) trace;

   interface Vector#(16,MSIX_Entry) msixEntry;

endinterface: PcieSplitter

// When TLP packets come in from the PCIe bus, they are dispatched to
// either the configuration register block, the portal (AXI slave) or
// the AXI master.
interface TLPDispatcher;

   // TLPs in from PCIe
   interface Put#(TLPData#(16)) tlp_in_from_bus;

   // TLPs out to the bridge implementation
   interface Get#(TLPData#(16)) tlp_out_to_config;
   interface Get#(TLPData#(16)) tlp_out_to_portal;
   interface Get#(TLPData#(16)) tlp_out_to_axi;
endinterface: TLPDispatcher

(* synthesize *)
module mkTLPDispatcher(TLPDispatcher);

   FIFO#(TLPData#(16))  tlp_in_fifo     <- mkFIFO();
   FIFOF#(TLPData#(16)) tlp_in_cfg_fifo <- mkGFIFOF(True,False); // unguarded enq
   FIFOF#(TLPData#(16)) tlp_in_portal_fifo <- mkGFIFOF(True,False); // unguarded enq
   FIFOF#(TLPData#(16)) tlp_in_axi_fifo <- mkGFIFOF(True,False); // unguarded enq

   Reg#(Bool) route_to_cfg <- mkReg(False);
   Reg#(Bool) route_to_portal <- mkReg(False);
   Reg#(Bool) route_to_axi <- mkReg(False);

   PulseWire is_read       <- mkPulseWire();
   PulseWire is_write      <- mkPulseWire();
   PulseWire is_completion <- mkPulseWire();

   (* fire_when_enabled *)
   rule dispatch_incoming_TLP;
      TLPData#(16) tlp = tlp_in_fifo.first();
      TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
      Bool is_config_read    =  tlp.sof
                             && (tlp.hit == 7'h01)
                             && (hdr_3dw.format == MEM_READ_3DW_NO_DATA)
                             ;
      Bool is_config_write   =  tlp.sof
                             && (tlp.hit == 7'h01)
                             && (hdr_3dw.format == MEM_WRITE_3DW_DATA)
                             && (hdr_3dw.pkttype != COMPLETION)
                             ;
      Bool is_axi_read       =  tlp.sof
                             && (tlp.hit == 7'h04)
                             && (hdr_3dw.format == MEM_READ_3DW_NO_DATA)
                             ;
      Bool is_axi_write      =  tlp.sof
                             && (tlp.hit == 7'h04)
                             && (hdr_3dw.format == MEM_WRITE_3DW_DATA)
                             && (hdr_3dw.pkttype != COMPLETION)
                             ;
      Bool is_axi_completion =  tlp.sof
                             && (hdr_3dw.format == MEM_WRITE_3DW_DATA)
                             && (hdr_3dw.pkttype == COMPLETION)
                             ;
      if (tlp.sof) begin
         // route the packet based on this header
         if (is_config_read || is_config_write) begin
            // send to config interface if it will accept
            if (tlp_in_cfg_fifo.notFull()) begin
               tlp_in_fifo.deq();
               tlp_in_cfg_fifo.enq(tlp);
               if (!tlp.eof)
                  route_to_cfg <= True;
            end
         end
         else if (is_axi_read || is_axi_write) begin
            // send to portal interface if it will accept
            if (tlp_in_portal_fifo.notFull()) begin
               tlp_in_fifo.deq();
               tlp_in_portal_fifo.enq(tlp);
               if (!tlp.eof)
                  route_to_portal <= True;
            end
         end
	 else if (is_axi_completion) begin
            // send to AXI interface if it will accept
            if (tlp_in_axi_fifo.notFull()) begin
               tlp_in_fifo.deq();
               tlp_in_axi_fifo.enq(tlp);
               if (!tlp.eof)
                  route_to_axi <= True;
            end
	 end
         else begin
            // unknown packet type -- just discard it
            tlp_in_fifo.deq();
         end
         // indicate activity type
         if (is_config_read)                     is_read.send();
         if (is_config_write)                    is_write.send();
      end
      else begin
         // this is a continuation of a previous TLP packet, so route
         // based on the last header
         if (route_to_cfg) begin
            // send to config interface if it will accept
            if (tlp_in_cfg_fifo.notFull()) begin
               tlp_in_fifo.deq();
               tlp_in_cfg_fifo.enq(tlp);
               if (tlp.eof)
                  route_to_cfg <= False;
            end
         end
         else if (route_to_portal) begin
            // send to portal interface if it will accept
            if (tlp_in_portal_fifo.notFull()) begin
               tlp_in_fifo.deq();
               tlp_in_portal_fifo.enq(tlp);
               if (tlp.eof)
                  route_to_portal <= False;
            end
         end
         else if (route_to_axi) begin
            // send to AXI interface if it will accept
            if (tlp_in_axi_fifo.notFull()) begin
               tlp_in_fifo.deq();
               tlp_in_axi_fifo.enq(tlp);
               if (tlp.eof)
                  route_to_axi <= False;
            end
         end
         else begin
            // unknown packet type -- just discard it
            tlp_in_fifo.deq();
         end
      end
   endrule: dispatch_incoming_TLP

   interface Put tlp_in_from_bus    = toPut(tlp_in_fifo);
   interface Get tlp_out_to_config  = toGet(tlp_in_cfg_fifo);
   interface Get tlp_out_to_portal  = toGet(tlp_in_portal_fifo);
   interface Get tlp_out_to_axi     = toGet(tlp_in_axi_fifo);
endmodule: mkTLPDispatcher

// Multiple sources of TLP packets must all share the PCIe bus. There
// is an arbiter which controls which source gets access to the PCIe
// endpoint.

interface TLPArbiter;

   // TLPs out to PCIe
   interface Get#(TLPData#(16)) tlp_out_to_bus;

   // TLPs in from the bridge implementation
   interface Put#(TLPData#(16)) tlp_in_from_config; // read completions
   interface Put#(TLPData#(16)) tlp_in_from_portal; // read completions
   interface Put#(TLPData#(16)) tlp_in_from_axi;    // read and write requests
endinterface: TLPArbiter

(* synthesize *)
module mkTLPArbiter(TLPArbiter);

   FIFO#(TLPData#(16))  tlp_out_fifo     <- mkFIFO();
   FIFOF#(TLPData#(16)) tlp_out_cfg_fifo <- mkGFIFOF(False,True); // unguarded deq
   FIFOF#(TLPData#(16)) tlp_out_portal_fifo <- mkGFIFOF(False,True); // unguarded deq
   FIFOF#(TLPData#(16)) tlp_out_axi_fifo <- mkGFIFOF(False,True); // unguarded deq

   Reg#(Bool) route_from_cfg <- mkReg(False);
   Reg#(Bool) route_from_portal <- mkReg(False);
   Reg#(Bool) route_from_axi <- mkReg(False);

   PulseWire is_read       <- mkPulseWire();
   PulseWire is_write      <- mkPulseWire();
   PulseWire is_completion <- mkPulseWire();

   (* fire_when_enabled *)
   rule arbitrate_outgoing_TLP;
      if (route_from_cfg) begin
         // continue taking from the config FIFO until end-of-frame
         if (tlp_out_cfg_fifo.notEmpty()) begin
            TLPData#(16) tlp = tlp_out_cfg_fifo.first();
            tlp_out_cfg_fifo.deq();
            tlp_out_fifo.enq(tlp);
            if (tlp.eof)
               route_from_cfg <= False;
         end
      end
      else if (route_from_portal) begin
         // continue taking from the portal FIFO until end-of-frame
         if (tlp_out_portal_fifo.notEmpty()) begin
            TLPData#(16) tlp = tlp_out_portal_fifo.first();
            tlp_out_portal_fifo.deq();
            tlp_out_fifo.enq(tlp);
            if (tlp.eof)
               route_from_portal <= False;
         end
      end
      else if (route_from_axi) begin
         // continue taking from the axi FIFO until end-of-frame
         if (tlp_out_axi_fifo.notEmpty()) begin
            TLPData#(16) tlp = tlp_out_axi_fifo.first();
            tlp_out_axi_fifo.deq();
            tlp_out_fifo.enq(tlp);
            if (tlp.eof)
               route_from_axi <= False;
         end
      end
      else if (tlp_out_cfg_fifo.notEmpty()) begin
         // prioritize config read completions over portal traffic
         TLPData#(16) tlp = tlp_out_cfg_fifo.first();
         tlp_out_cfg_fifo.deq();
         if (tlp.sof) begin
            tlp_out_fifo.enq(tlp);
            if (!tlp.eof)
               route_from_cfg <= True;
            is_completion.send();
         end
      end
      else if (tlp_out_portal_fifo.notEmpty()) begin
         // prioritize portal read completions over AXI master traffic
         TLPData#(16) tlp = tlp_out_portal_fifo.first();
         tlp_out_portal_fifo.deq();
         if (tlp.sof) begin
            tlp_out_fifo.enq(tlp);
            if (!tlp.eof)
               route_from_portal <= True;
            is_completion.send();
         end
      end
      else if (tlp_out_axi_fifo.notEmpty()) begin
         TLPData#(16) tlp = tlp_out_axi_fifo.first();
         tlp_out_axi_fifo.deq();
         if (tlp.sof) begin
            tlp_out_fifo.enq(tlp);
            if (!tlp.eof)
               route_from_axi <= True;
            is_completion.send();
         end
      end
   endrule: arbitrate_outgoing_TLP

   interface Get tlp_out_to_bus     = toGet(tlp_out_fifo);
   interface Put tlp_in_from_config = toPut(tlp_out_cfg_fifo);
   interface Put tlp_in_from_portal = toPut(tlp_out_portal_fifo);
   interface Put tlp_in_from_axi    = toPut(tlp_out_axi_fifo);
endmodule

// The PCIe-to-AXI bridge puts all of the elements together
module mkPcieSplitter#(PciId my_id)(PcieSplitter#(bpb))
   provisos( Add#(1, __1, TDiv#(bpb,4))
           // the compiler should be able to figure these out ...
           , Log#(TAdd#(1,bpb), TLog#(TAdd#(bpb,1)))
           , Add#(TAdd#(bpb,20), __2, TMul#(TDiv#(TMul#(TAdd#(bpb,20),9),36),4))
           );

   Integer bytes_per_beat = valueOf(bpb);

   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
   MakeResetIfc portalResetIfc <- mkReset(10, False, defaultClock);

   // instantiate sub-components

   TLPDispatcher        dispatcher <- mkTLPDispatcher();
   TLPArbiter           arbiter    <- mkTLPArbiter();
   AxiControlAndStatusRegs csr     <- mkAxiControlAndStatusRegs(portalResetIfc);
   AxiMasterEngine axiMasterEngine <- mkAxiMasterEngine(my_id);
   mkConnection(axiMasterEngine.master, csr.slave);

   Reg#(Bit#(32)) timestamp <- mkReg(0);
   rule incTimestamp;
       timestamp <= timestamp + 1;
   endrule
//   rule endTrace if (csr.tlpTracing && csr.tlpTraceLimit != 0 && csr.tlpTraceBramWrAddr > truncate(csr.tlpTraceLimit));
//       csr.tlpTracing <= False;
//   endrule

   // connect the sub-components to each other

   mkConnection(dispatcher.tlp_out_to_config,    axiMasterEngine.tlp_in);
   // mkConnection(dispatcher.tlp_out_to_portal,    portalEngine.tlp_in);

   mkConnection(axiMasterEngine.tlp_out,                     arbiter.tlp_in_from_config);
   //mkConnection(portalEngine.tlp_out,            arbiter.tlp_in_from_portal);

   FIFO#(TLPData#(16)) tlpFromBusFifo <- mkFIFO();
   Reg#(Bool) skippingIncomingTlps <- mkReg(False);
   PulseWire fromPcie <- mkPulseWire;
   PulseWire   toPcie <- mkPulseWire;
   Wire#(TLPData#(16)) fromPcieTlp <- mkDWire(unpack(0));
   Wire#(TLPData#(16))   toPcieTlp <- mkDWire(unpack(0));
   rule traceTlpFromBus;
       let tlp = tlpFromBusFifo.first;
       tlpFromBusFifo.deq();
       dispatcher.tlp_in_from_bus.put(tlp);
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
       let tlp <- arbiter.tlp_out_to_bus.get();
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

   interface toPciGet = toGet(tlpToBusFifo);
   interface fromPciPut = toPut(tlpFromBusFifo);
   interface PcieBridge brif;
       interface GetPut master = tuple2(dispatcher.tlp_out_to_portal, arbiter.tlp_in_from_portal); //portalEngine.master;
       interface GetPut slave = tuple2(dispatcher.tlp_out_to_axi, arbiter.tlp_in_from_axi);
       interface Reset portalReset = portalResetIfc.new_rst;
       interface Put trace;
           method Action put(TimestampedTlpData ttd);
	       if (csr.tlpTracing) begin
	           ttd.timestamp = timestamp;
	           csr.toPcieTraceBramPort.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: truncate(csr.toPcieTraceBramWrAddr), datain: ttd });
	           csr.toPcieTraceBramWrAddr <= csr.toPcieTraceBramWrAddr + 1;
	       end
           endmethod
       endinterface: trace
   endinterface

   // method Action interrupt();
   //     portalEngine.interruptRequested <= True;
   // endmethod
   
   interface Vector msixEntry = csr.msixEntry;
      
endmodule: mkPcieSplitter

endpackage: PcieSplitter
