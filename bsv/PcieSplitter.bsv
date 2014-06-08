
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
Integer portInterrupt = 2;
Integer portAxi    = 3;
typedef 4 PortMax;

// When TLP packets come in from the PCIe bus, they are dispatched to
// either the configuration register block, the portal (AXI slave) or
// the AXI master.
interface TLPDispatcher;
   // TLPs in from PCIe
   interface Put#(TLPData#(16)) inFromBus;
   // TLPs out to the bridge implementation
   interface Vector#(PortMax, Get#(TLPData#(16))) out;
endinterface: TLPDispatcher

typedef function Bool tlpMatchFunction(TLPData#(16) tlp, TLPMemoryIO3DWHeader hdr_3dw) TlpMatchFunction;

(* synthesize *)
module mkTLPDispatcher(TLPDispatcher);
   FIFO#(TLPData#(16))  tlp_in_fifo     <- mkFIFO();
   Vector#(PortMax, FIFOF#(TLPData#(16))) tlp_out_fifo <- replicateM(mkGFIFOF(True,False)); // unguarded enq
   Reg#(Maybe#(Bit#(TLog#(PortMax)))) routeToPort <- mkReg(tagged Invalid);
   Vector#(PortMax, TlpMatchFunction) matchFunctions = newVector;

   function Bool configMatch(TLPData#(16) tlp, TLPMemoryIO3DWHeader hdr_3dw);
      return tlp.hit == 7'h01 &&
          (hdr_3dw.format == MEM_READ_3DW_NO_DATA /* read */
        || (hdr_3dw.format == MEM_WRITE_3DW_DATA && hdr_3dw.pkttype != COMPLETION)); /* write */
   endfunction

   function Bool axiMatch(TLPData#(16) tlp, TLPMemoryIO3DWHeader hdr_3dw);
      return tlp.hit == 7'h04 &&
          (hdr_3dw.format == MEM_READ_3DW_NO_DATA /* read */
        || (hdr_3dw.format == MEM_WRITE_3DW_DATA && hdr_3dw.pkttype != COMPLETION)); /* write */
   endfunction

   function Bool axiCompletionMatch(TLPData#(16) tlp, TLPMemoryIO3DWHeader hdr_3dw);
      return hdr_3dw.format == MEM_WRITE_3DW_DATA && hdr_3dw.pkttype == COMPLETION;
   endfunction

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
            if (!matched && matchFunctions[port](tlp, hdr_3dw)) begin
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
      end
      else if (routeToPort matches tagged Valid .port) begin
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
   Reg#(Maybe#(Bit#(TLog#(PortMax)))) routeFrom <- mkReg(tagged Invalid);

   (* fire_when_enabled *)
   rule arbitrate_outgoing_TLP;
      if (routeFrom matches tagged Valid .port) begin
         if (tlp_in_fifo[port].notEmpty()) begin
            TLPData#(16) tlp <- toGet(tlp_in_fifo[port]).get();
            tlp_out_fifo.enq(tlp);
            if (tlp.eof)
               routeFrom <= tagged Invalid;
         end
      end
      else begin
	 Bool sentOne = False;
	 for (Integer port = 0; port < valueOf(PortMax); port = port+1) begin
	    if (!sentOne && tlp_in_fifo[port].notEmpty()) begin
               TLPData#(16) tlp <- toGet(tlp_in_fifo[port]).get();
	       sentOne = True;
               if (tlp.sof) begin
		  tlp_out_fifo.enq(tlp);
		  if (!tlp.eof)
		     routeFrom <= tagged Valid fromInteger(port);
               end
	    end
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
