
import Vector::*;
import FIFO::*;

import Portal::*;

interface DirectoryRequest;
   method Action timeStamp();
   method Action numPortals();
   method Action portalAddrBits();
   method Action idOffset(Bit#(32) id);
   method Action idType(Bit#(32) id);
endinterface

interface DirectoryResponse;
   method Action timeStamp(Bit#(64) t);
   method Action numPortals(Bit#(32) n);
   method Action portalAddrBits(Bit#(32) n);
   method Action idOffset(Bit#(32) id, Bit#(32) o);
   method Action idType(Bit#(32) id, Bit#(64) t);
endinterface

module mkDirectoryRequest#(Vector#(n,StdPortal) portals, DirectoryResponse resp) (DirectoryRequest);

   FIFO#(Bit#(32)) offReqQ <- mkFIFO;
   FIFO#(Bit#(32)) typeReqQ <- mkFIFO;
   Reg#(Bit#(32)) offPtr <- mkReg(0);
   Reg#(Bit#(32)) typePtr <- mkReg(0);
   
   rule searchOff;
      if (offReqQ.first == portals[offPtr].ifcId) begin
	 offReqQ.deq;
	 resp.idOffset(offReqQ.first, zeroExtend(offPtr));
      end
      else if(offPtr+1 == fromInteger(valueOf(n))) begin
	 resp.idOffset(offReqQ.first, maxBound);
	 offPtr <= 0;
	 offReqQ.deq;
      end
      else begin
	 offPtr <= offPtr+1;
      end
   endrule

   rule searchType;
      if (typeReqQ.first == portals[typePtr].ifcId) begin
	 typeReqQ.deq;
	 resp.idType(typeReqQ.first, portals[typePtr].ifcType);
      end
      else if(typePtr+1 == fromInteger(valueOf(n))) begin
	 resp.idType(typeReqQ.first, maxBound);
	 typePtr <= 0;
	 typeReqQ.deq;
      end
      else begin
	 typePtr <= typePtr+1;
      end
   endrule
   
   method Action timeStamp();
      let rv <- $time;
      resp.timeStamp(rv);
   endmethod
   method Action numPortals();
      resp.numPortals(fromInteger(valueOf(n)));
   endmethod
   method Action portalAddrBits();
      resp.portalAddrBits(0);
   endmethod
   method Action idOffset(Bit#(32) id);
      offReqQ.enq(id);
   endmethod
   method Action idType(Bit#(32) id);
      typeReqQ.enq(id);
   endmethod

endmodule


