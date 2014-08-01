
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

import Vector::*;
import Arith ::*;
import FIFOF ::*;
import GetPut::*;
import MIMO  ::*; //LUInt

interface MIFO#(numeric type max_in, numeric type n_out, numeric type size, type t);
   method    Action                      enq(LUInt#(max_in) count, Vector#(max_in, t) data);
   method    Vector#(n_out, t)           first();
   method    Action                      deq();
      
   (* always_ready *)
   method    Bool                        enqReady();
   (* always_ready *)
   method    Bool                        deqReady();
endinterface
   
module mkMIFO(MIFO#(max_in, n_out, size, t))
   provisos (Log#(max_in, max_in_sz),
	     Log#(n_out, n_out_sz),
	     Add#(n_out, a__, max_in),
	     Add#(1, b__, n_out),
	     Bits#(t, c__),
	     Bits#(Vector#(max_in, t), d__),
	     Add#(e__, max_in_sz, TLog#(TAdd#(max_in, 1))),
      Add#(f__, 2, max_in_sz)
      );
   FIFOF#(Vector#(max_in, t))     inFifo <- mkFIFOF();
   FIFOF#(UInt#(max_in_sz))      posFifo <- mkFIFOF();
   FIFOF#(LUInt#(max_in))    inCountFifo <- mkFIFOF();
   FIFOF#(Bit#(max_in))           weFifo <- mkFIFOF();
   Vector#(max_in, FIFOF#(t)) fifos      <- replicateM(mkFIFOF());

   Reg#(UInt#(max_in_sz))            inPos <- mkReg(0);
   Reg#(UInt#(max_in_sz))            outPos <- mkReg(0);

   LUInt#(max_in) i_max_in = fromInteger(valueOf(max_in));

   let verbose = False;

   function a fifoFirst(FIFOF#(a) fifo); if (fifo.notEmpty()) return fifo.first(); else return ?; endfunction
   function Bool fifoNotEmpty(FIFOF#(a) fifo); return fifo.notEmpty(); endfunction
   function Bool fifoNotFull(FIFOF#(a) fifo); return fifo.notFull(); endfunction

   FIFOF#(Bool) checkInFifo <- mkFIFOF();
   rule checkin if (verbose);
      let v <- toGet(checkInFifo).get();
      $display("checkIn: inPos=%d outPos=%d notEmpties: %h notFulls: %h values: %h",
	       inPos, outPos, map(fifoNotEmpty, fifos), map(fifoNotFull, fifos), map(fifoFirst, fifos));
   endrule

   rule tofifos;
      let values = inFifo.first;
      let count  = inCountFifo.first;
      let pos    = posFifo.first;
      let we     = weFifo.first;


      Bool ready = True;
      for (Integer i = 0; i < valueOf(max_in); i = i+1) begin
	 if (we[i] == 1)
	    ready = ready && fifos[i].notFull();
      end
      if (ready) begin
	 for (Integer i = 0; i < valueOf(max_in); i = i+1) begin
	    if (we[i] == 1)
	       fifos[i].enq(values[i]);
	 end
	 inFifo.deq();
	 inCountFifo.deq();
	 weFifo.deq();
	 posFifo.deq();

	 if (verbose) begin
	    $display("tofifos: pos=%d count=%d we=%h", pos, count, we, " values: %h notFull: %h", values, map(fifoNotFull, fifos));
	    checkInFifo.enq(True);
	 end
      end
   endrule

   function Bool deqReadyInternal();
      LUInt#(max_in) rot = i_max_in - extend(outPos);
      Vector#(n_out, Bool) notEmpties = take(rotateBy(map(fifoNotEmpty, fifos), truncate(rot)));
      return fold(booland, notEmpties);
   endfunction

   FIFOF#(Bool) checkFifo <- mkFIFOF();
   rule check if (verbose);
      let v <- toGet(checkFifo).get();
      LUInt#(max_in) rot = i_max_in - extend(outPos);
      Vector#(max_in, Bool) allNotEmpties = map(fifoNotEmpty, fifos);
      Vector#(max_in, Bool) notEmpties = rotateBy(map(fifoNotEmpty, fifos), truncate(rot));
      Vector#(4, Bool) testv = replicate(False);
      testv[outPos] = True;
      UInt#(2) testpos = 3 - truncate(outPos);
      Vector#(4, Bool) rotatedTestv = rotateBy(testv, 1);
      if (verbose)
      $display("check outPos: ", outPos, " notEmpty: ", fifos[outPos].notEmpty(),
	 " notEmpties: ", notEmpties, " allNotEmpties: %h", allNotEmpties);
   endrule

   method    Action                      enq(LUInt#(max_in) count, Vector#(max_in, t) data);
      function Bool lessThanCount(Integer i); return fromInteger(i) < count; endfunction
      Vector#(max_in, Bool) we = genWith(lessThanCount);
      inFifo.enq(rotateBy(data, inPos));
      inCountFifo.enq(count);
      weFifo.enq(pack(rotateBy(we, inPos)));
      posFifo.enq(inPos);
      inPos <= truncate((extend(inPos) + count) % i_max_in);

      if (verbose) $display("enq: inPos=%d we=%h", inPos, we);
   endmethod

   method    Vector#(n_out, t)           first if (deqReadyInternal());
      function t firstN(Integer i);
	 return fifos[(extend(outPos) + fromInteger(i)) % i_max_in].first;
      endfunction
      return genWith(firstN);
   endmethod

   method    Action                      deq() if (deqReadyInternal());
      function t firstN(Integer i);
	 return fifos[(extend(outPos) + fromInteger(i)) % i_max_in].first;
      endfunction
      for (Integer i = 0; i < valueOf(n_out); i = i+1)
	 fifos[(extend(outPos) + fromInteger(i)) % i_max_in].deq();
      UInt#(max_in_sz) nextOutPos = truncate((extend(outPos) + fromInteger(valueOf(n_out))) % i_max_in);
      outPos <= nextOutPos;

      if (verbose) begin
	 LUInt#(max_in) rot = i_max_in - extend(outPos);
	 Vector#(n_out, t) v = genWith(firstN);
	 Vector#(max_in, Bool) allNotEmpties = rotateBy(map(fifoNotEmpty, fifos), truncate(rot));
	 Vector#(n_out, Bool) notEmpties = take(map(fifoNotEmpty, rotateBy(fifos, truncate(rot))));
	 $display("first: ", v, " outPos: ", outPos, " nextOutPos: ", nextOutPos, " nextNotEmpty: ", fifos[nextOutPos].notEmpty(),
	    " notEmpties: ", notEmpties, " allNotEmpties: %h", allNotEmpties);
	 checkFifo.enq(True);
      end
   endmethod
      
   method    Bool                        enqReady = inFifo.notFull;

   method    Bool                        deqReady = deqReadyInternal;

endmodule