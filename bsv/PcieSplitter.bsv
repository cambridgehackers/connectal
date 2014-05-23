
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
import PCIE         :: *;
import Clocks       :: *;
import ClientServer :: *;

Integer portConfig = 0;
Integer portPortal = 1;
Integer portAxi    = 2;
typedef 3 PortMax;

// When TLP packets come in from the PCIe bus, they are dispatched to
// either the configuration register block, the portal (AXI slave) or
// the AXI master.
interface TLPDispatcher;
   // TLPs in from PCIe
   interface Put#(TLPData#(16)) inFromBus;
   // TLPs out to the bridge implementation
   interface Vector#(PortMax, Get#(TLPData#(16))) out;
endinterface: TLPDispatcher

typedef function Bool tlpMatchFunction(TLPData#(16) tlp) TlpMatchFunction;

(* synthesize *)
module mkTLPDispatcher(TLPDispatcher);
   FIFO#(TLPData#(16))  tlp_in_fifo     <- mkFIFO();
   Vector#(PortMax, FIFOF#(TLPData#(16))) tlp_out_fifo <- replicateM(mkGFIFOF(True,False)); // unguarded enq
   Reg#(Maybe#(Bit#(TLog#(PortMax)))) routeToPort <- mkReg(tagged Invalid);

   PulseWire is_read       <- mkPulseWire();
   PulseWire is_write      <- mkPulseWire();
   PulseWire is_completion <- mkPulseWire();

   function Bool configMatch(TLPData#(16) tlp);
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
      return is_config_read || is_config_write;
   endfunction

   function Bool axiMatch(TLPData#(16) tlp);
      TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
      Bool is_axi_read       =  tlp.sof
                             && (tlp.hit == 7'h04)
                             && (hdr_3dw.format == MEM_READ_3DW_NO_DATA)
                             ;
      Bool is_axi_write      =  tlp.sof
                             && (tlp.hit == 7'h04)
                             && (hdr_3dw.format == MEM_WRITE_3DW_DATA)
                             && (hdr_3dw.pkttype != COMPLETION)
                             ;
      return is_axi_read || is_axi_write;
   endfunction

   function Bool axiCompletionMatch(TLPData#(16) tlp);
      TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
      Bool is_axi_completion =  tlp.sof
                             && (hdr_3dw.format == MEM_WRITE_3DW_DATA)
                             && (hdr_3dw.pkttype == COMPLETION)
                             ;
      return is_axi_completion;
   endfunction

   Vector#(PortMax, TlpMatchFunction) matchFunctions = newVector;
   matchFunctions[portConfig] = configMatch;
   matchFunctions[portPortal] = axiMatch;
   matchFunctions[portAxi]    = axiCompletionMatch;

   (* fire_when_enabled *)
   rule dispatch_incoming_TLP;
      TLPData#(16) tlp = tlp_in_fifo.first();
      TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);

      if (tlp.sof) begin
	 Bool matched = False;
         // route the packet based on this header
	 for (Integer port = 0; port < valueOf(PortMax); port = port+1)
            if (!matched && matchFunctions[port](tlp)) begin
	       matched = True;
               if (tlp_out_fifo[port].notFull()) begin
		  tlp_in_fifo.deq();
		  tlp_out_fifo[port].enq(tlp);
		  if (!tlp.eof)
                     routeToPort <= tagged Valid fromInteger(port);
               end
            end
         if (!matched) begin
            // unknown packet type -- just discard it
            tlp_in_fifo.deq();
         end
         // indicate activity type
         //if (is_config_read)                     is_read.send();
         //if (is_config_write)                    is_write.send();
      end
      else begin
	 if (routeToPort matches tagged Valid .port) begin
            if (tlp_out_fifo[port].notFull()) begin
               tlp_in_fifo.deq();
               tlp_out_fifo[port].enq(tlp);
               if (tlp.eof)
                  routeToPort <= tagged Invalid;
            end
         end
         else begin
            // unknown packet type -- just discard it
            tlp_in_fifo.deq();
         end
      end
   endrule: dispatch_incoming_TLP

   Vector#(PortMax, Get#(TLPData#(16))) outtemp;
   for (Integer i = 0; i < valueOf(PortMax); i=i+1)
       outtemp[i] = toGet(tlp_out_fifo[i]);
   interface out = outtemp;
   interface Put inFromBus    = toPut(tlp_in_fifo);
endmodule: mkTLPDispatcher

// Multiple sources of TLP packets must all share the PCIe bus. There
// is an arbiter which controls which source gets access to the PCIe
// endpoint.

interface TLPArbiter;
   // TLPs out to PCIe
   interface Get#(TLPData#(16)) outToBus;
   // TLPs in from the bridge implementation
   interface Vector#(PortMax, Put#(TLPData#(16))) in;
endinterface: TLPArbiter

(* synthesize *)
module mkTLPArbiter(TLPArbiter);
   FIFO#(TLPData#(16))  tlp_out_fifo     <- mkFIFO();
   Vector#(PortMax, FIFOF#(TLPData#(16))) tlp_in_fifo <- replicateM(mkGFIFOF(False,True)); // unguarded deq
   Vector#(PortMax, Reg#(Bool)) route_from <- replicateM(mkReg(False));

   PulseWire is_read       <- mkPulseWire();
   PulseWire is_write      <- mkPulseWire();
   PulseWire is_completion <- mkPulseWire();

   (* fire_when_enabled *)
   rule arbitrate_outgoing_TLP;
      if (route_from[portConfig]) begin
         // continue taking from the config FIFO until end-of-frame
         if (tlp_in_fifo[portConfig].notEmpty()) begin
            TLPData#(16) tlp = tlp_in_fifo[portConfig].first();
            tlp_in_fifo[portConfig].deq();
            tlp_out_fifo.enq(tlp);
            if (tlp.eof)
               route_from[portConfig] <= False;
         end
      end
      else if (route_from[portPortal]) begin
         // continue taking from the portal FIFO until end-of-frame
         if (tlp_in_fifo[portPortal].notEmpty()) begin
            TLPData#(16) tlp = tlp_in_fifo[portPortal].first();
            tlp_in_fifo[portPortal].deq();
            tlp_out_fifo.enq(tlp);
            if (tlp.eof)
               route_from[portPortal] <= False;
         end
      end
      else if (route_from[portAxi]) begin
         // continue taking from the axi FIFO until end-of-frame
         if (tlp_in_fifo[portAxi].notEmpty()) begin
            TLPData#(16) tlp = tlp_in_fifo[portAxi].first();
            tlp_in_fifo[portAxi].deq();
            tlp_out_fifo.enq(tlp);
            if (tlp.eof)
               route_from[portAxi] <= False;
         end
      end
      else if (tlp_in_fifo[portConfig].notEmpty()) begin
         // prioritize config read completions over portal traffic
         TLPData#(16) tlp = tlp_in_fifo[portConfig].first();
         tlp_in_fifo[portConfig].deq();
         if (tlp.sof) begin
            tlp_out_fifo.enq(tlp);
            if (!tlp.eof)
               route_from[portConfig] <= True;
            is_completion.send();
         end
      end
      else if (tlp_in_fifo[portPortal].notEmpty()) begin
         // prioritize portal read completions over AXI master traffic
         TLPData#(16) tlp = tlp_in_fifo[portPortal].first();
         tlp_in_fifo[portPortal].deq();
         if (tlp.sof) begin
            tlp_out_fifo.enq(tlp);
            if (!tlp.eof)
               route_from[portPortal] <= True;
            is_completion.send();
         end
      end
      else if (tlp_in_fifo[portAxi].notEmpty()) begin
         TLPData#(16) tlp = tlp_in_fifo[portAxi].first();
         tlp_in_fifo[portAxi].deq();
         if (tlp.sof) begin
            tlp_out_fifo.enq(tlp);
            if (!tlp.eof)
               route_from[portAxi] <= True;
            is_completion.send();
         end
      end
   endrule: arbitrate_outgoing_TLP

   Vector#(PortMax, Put#(TLPData#(16))) intemp;
   for (Integer i = 0; i < valueOf(PortMax); i=i+1)
       intemp[i] = toPut(tlp_in_fifo[i]);
   interface in = intemp;
   interface Get outToBus     = toGet(tlp_out_fifo);
endmodule
endpackage: PcieSplitter
