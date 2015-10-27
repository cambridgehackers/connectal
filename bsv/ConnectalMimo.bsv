////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2012  Bluespec, Inc.  ALL RIGHTS RESERVED.
// $Revision: 32844 $
// $Date: 2013-12-16 16:39:44 +0000 (Mon, 16 Dec 2013) $
////////////////////////////////////////////////////////////////////////////////
//  Filename      : MIMO.bsv
//  Description   : Multiple-In Multiple-Out
////////////////////////////////////////////////////////////////////////////////
package ConnectalMimo;

// Notes :
// - This module works like a FIFO, but for arbitrary amounts of the base object type.
// - The clear method overrides the effects of enq and deq.

////////////////////////////////////////////////////////////////////////////////
/// Imports
////////////////////////////////////////////////////////////////////////////////
import Vector            ::*;
import DefaultValue      ::*;
import BUtils            ::*;
import FIFO              ::*;
import FIFOF             ::*;
import BRAMFIFO          ::*;
import Counter           ::*;
import Clocks            ::*;
import MIMO              ::*;

import ConnectalBramFifo ::*;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
///
/// Implementation of BRAM based version
///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module mkMIMOBram#(MIMOConfiguration cfg)(MIMO#(max_in, max_out, size, t))
   provisos (  Bits#(t, st)               // object must have bit representation
	     , Add#(__f, 1, st)           // object is at least 1 byte in size
	     , Add#(2, __a, size)         // must have at least 2 elements of storage
	     , Add#(__b, max_in, size)    // the max enqueued amount must be less than or equal to the full storage
	     , Add#(__c, max_out, size)   // the max dequeued amount must be less than or equal to the full storage
             , Mul#(st, size, total)      // total bits of storage
             , Mul#(st, max_in, intot)    // total bits to be enqueued
             , Mul#(st, max_out, outtot)  // total bits to be dequeued
             , Add#(__d, outtot, total)   // make sure the number of dequeue bits is not larger than the total storage
	     , Max#(max_in, max_out, max) // calculate the max width of the memories
	     , Div#(size, max, em1)       // calculate the number of entries for each memory required
	     , Add#(em1, 1, e)
	     , Add#(__e, max_out, max)
             );
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();
   Vector#(max, FIFOF#(t))         vfStorage           <- replicateM(mkDualClockBramFIFOF(clock, reset, clock, reset));
   Counter#(32)                    rDataCount          <- mkCounter(0);
   
   Reg#(LUInt#(max))               rWriteIndex         <- mkReg(0);
   Reg#(LUInt#(max))               rReadIndex          <- mkReg(0);
   
   Vector#(max, RWire#(Bool))      vrwDeqFifo          <- replicateM(mkRWire);
   Vector#(max, RWire#(t))         vrwEnqFifo          <- replicateM(mkRWire);
 
   RWire#(LUInt#(size))            rwDeqCount          <- mkRWire;
   RWire#(LUInt#(size))            rwEnqCount          <- mkRWire;
   RWire#(Bit#(intot))             rwEnqData           <- mkRWire;
   PulseWire                       pwClear             <- mkPulseWire;
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Functions
   ////////////////////////////////////////////////////////////////////////////////
   function t getFirst(FIFOF#(t) ifc);
      return ifc.first();
   endfunction

   function Action doEnq(Bool doit, FIFOF#(t) ifc, t datain);
      action
	 if (doit) ifc.enq(datain);
      endaction
   endfunction

   function Action doDeq(Bool doit, FIFOF#(t) ifc);
      action
	 if (doit) ifc.deq();
      endaction
   endfunction
   
   function Vector#(max, Bool) createMask(LUInt#(max) count);
      Bit#(max) v = (1 << count) - 1;
      return unpack(v);
   endfunction
   
   function Vector#(v, el) rotateRBy(Vector#(v, el) vect, UInt#(logv) n)
      provisos(Log#(v, logv));
      return reverse(rotateBy(reverse(vect), n));
   endfunction
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Rules
   ////////////////////////////////////////////////////////////////////////////////
   Rules d = 
   rules
      (* aggressive_implicit_conditions *)
      rule dequeue if (rwDeqCount.wget matches tagged Valid .dcount);
	 Vector#(max, Bool) deqDoIt = rotateBy(createMask(cExtend(dcount)), cExtend(rReadIndex));
	 for(Integer i = 0; i < valueOf(max); i = i + 1) begin
	    if (deqDoIt[i]) vrwDeqFifo[i].wset(True);
	 end
	 
	 rDataCount.dec(cExtend(dcount));
	 
	 UInt#(32) ridx = cExtend(rReadIndex);
	 UInt#(32) dcnt = cExtend(dcount);
	 if ((ridx + dcnt) >= fromInteger(valueOf(max))) 
	    rReadIndex <= rReadIndex - fromInteger(valueOf(max)) + cExtend(dcount);
	 else
	    rReadIndex <= rReadIndex + cExtend(dcount);
      endrule
      
      (* aggressive_implicit_conditions *)
      rule enqueue if (rwEnqCount.wget matches tagged Valid .ecount &&& 
		      rwEnqData.wget matches tagged Valid .edata
		      );
	 Vector#(max, t)    enqData = rotateBy(unpack(cExtend(edata)), cExtend(rWriteIndex));
	 Vector#(max, Bool) enqDoIt = rotateBy(createMask(cExtend(ecount)), cExtend(rWriteIndex));
	 
	 for(Integer i = 0; i < valueOf(max); i = i + 1) begin
	    if (enqDoIt[i]) vrwEnqFifo[i].wset(enqData[i]);
	 end
	 
	 rDataCount.inc(cExtend(ecount));
	 
	 UInt#(32) widx = cExtend(rWriteIndex);
	 UInt#(32) ecnt = cExtend(ecount);
	 if ((widx + ecnt) >= fromInteger(valueOf(max))) 
	    rWriteIndex <= rWriteIndex - fromInteger(valueOf(max)) + cExtend(ecount);
	 else
	    rWriteIndex <= rWriteIndex + cExtend(ecount);
      endrule
   endrules;

   Rules re = emptyRules;
   for(Integer i = 0; i < valueOf(max); i = i + 1) begin
      re = rJoinConflictFree(re, 
	 rules
	    rule enqueue_fifo if (vrwEnqFifo[i].wget matches tagged Valid .enqdata);
	       vfStorage[i].enq(enqdata);
	    endrule
	 endrules
	 );
   end
   
   Rules rd = emptyRules;
   for(Integer i = 0; i < valueOf(max); i = i + 1) begin
      rd = rJoinConflictFree(rd, 
	 rules
	    rule dequeue_fifo if (vrwDeqFifo[i].wget matches tagged Valid .*);
	       vfStorage[i].deq();
	    endrule
	 endrules
	 );
   end
   
   Rules r = rJoinConflictFree(rd, re);
   r = rJoin(d, r);
   r = rJoinPreempts(
		     rules
			(* fire_when_enabled *)
			rule clear if (pwClear);
			   function Action getClear(FIFOF#(t) ifc) = ifc.clear();
			   rDataCount.setF(0);
			   rWriteIndex <= 0;
			   rReadIndex <= 0;
			   joinActions(map(getClear, vfStorage));
			endrule
		     endrules, r);
   
   addRules(r);
   
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   method Action enq(LUInt#(max_in) count, Vector#(max_in, t) data) if (cfg.unguarded || (rDataCount.value() < fromInteger(valueOf(size))));
      rwEnqCount.wset(cExtend(count));
      rwEnqData.wset(pack(data));
   endmethod
   
   method Vector#(max_out, t) first() if (cfg.unguarded || (rDataCount.value() > 0));
      Vector#(max, t) v = newVector;
      for(Integer i = 0; i < valueOf(max); i = i + 1) begin
	 if (vfStorage[i].notEmpty()) v[i] = vfStorage[i].first();
	 else                         v[i] = ?;
      end
      return take(rotateRBy(v, cExtend(rReadIndex)));
   endmethod
      
   method Action deq(LUInt#(max_out) count) if (cfg.unguarded || (rDataCount.value() > 0));
      LUInt#(size) szcount = cExtend(count);
      rwDeqCount.wset(szcount);
   endmethod
         
   method Bool enqReady();
      return rDataCount.value < fromInteger(valueOf(size));
   endmethod
   
   method Bool enqReadyN(LUInt#(max_in) count);
      return (rDataCount.value() + cExtend(count)) <= fromInteger(valueOf(size));
   endmethod
      
   method Bool deqReady();
      return rDataCount.value() > 0;
   endmethod
   
   method Bool deqReadyN(LUInt#(max_out) count);
      return rDataCount.value() >= cExtend(count);
   endmethod
   
   method LUInt#(size) count();
      return cExtend(rDataCount.value());
   endmethod
   
   method Action clear();
      pwClear.send();
   endmethod
endmodule: mkMIMOBram
endpackage: ConnectalMimo

