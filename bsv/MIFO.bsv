
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
import Pipe  ::*;
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
   
instance ToGet #(MIFO #(max_in, n_out, size, a), Vector#(n_out, a));
   function Get #(Vector#(n_out, a)) toGet (MIFO #(max_in, n_out, size, a) mifo);
      return (interface Get;
                 method ActionValue #(Vector#(n_out, a)) get ();
                    mifo.deq ();
                    return mifo.first ();
                 endmethod
              endinterface);
   endfunction
endinstance

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
   Vector#(max_in, FIFOF#(t)) fifos      <- replicateM(mkSizedFIFOF(valueOf(size)));

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
      // for (Integer i = 0; i < valueOf(max_in); i = i+1) begin
      // 	 if (we[i] == 1)
      // 	    ready = ready && fifos[i].notFull();
      // end
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


interface FIMO#(numeric type n_in, numeric type max_out, numeric type size, type t);
   interface PipeIn#(Vector#(n_in, t)) in;
   interface Vector#(TAdd#(max_out,1), PipeOut#(Vector#(max_out, t))) out;
endinterface

module mkFIMO(FIMO#(n_in, max_out, size, t))
   provisos (Log#(n_in, n_in_sz),
	     Log#(max_out, max_out_sz),
	     Add#(n_in, a__, max_out),
	     Add#(1, b__, max_out),
	     Bits#(t, c__),
	     Add#(d__, max_out_sz, TLog#(TAdd#(max_out, 1)))
      );
   FIFOF#(Vector#(max_out, t))     inFifo <- mkFIFOF();
   FIFOF#(UInt#(max_out_sz))      posFifo <- mkFIFOF();
   FIFOF#(Bit#(max_out))           weFifo <- mkFIFOF();
   Vector#(max_out, FIFOF#(t))      fifos <- replicateM(mkFIFOF());

   Reg#(UInt#(max_out_sz))            inPos <- mkReg(0);
   Reg#(UInt#(max_out_sz))            outPos <- mkReg(0);

   LUInt#(max_out) i_n_in = fromInteger(valueOf(n_in));
   LUInt#(max_out) i_max_out = fromInteger(valueOf(max_out));

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
      let pos    = posFifo.first;
      let we     = weFifo.first;


      Bool ready = True;
      // for (Integer i = 0; i < valueOf(max_out); i = i+1) begin
      // 	 if (we[i] == 1)
      // 	    ready = ready && fifos[i].notFull();
      // end
      $display("tofifos: we=%h", we);
      if (ready) begin
	 for (Integer i = 0; i < valueOf(max_out); i = i+1) begin
	    if (we[i] == 1)
	       fifos[i].enq(values[i]);
	 end
	 inFifo.deq();
	 weFifo.deq();
	 posFifo.deq();

	 if (verbose) begin
	    $display("tofifos: pos=%d we=%h", pos, we, " values: %h notFull: %h", values, map(fifoNotFull, fifos));
	    checkInFifo.enq(True);
	 end
      end
   endrule

   function Bool deqReadyInternal(Integer n_out);
      LUInt#(max_out) rot = i_max_out - extend(outPos);
      Vector#(max_out, Bool) notEmpties = rotateBy(map(fifoNotEmpty, fifos), truncate(rot));

      function Bool n_notEmpty(Integer i); if (i < n_out) return notEmpties[i]; else return True; endfunction
      Vector#(max_out, Bool) n_notEmpties = genWith(n_notEmpty);

      return fold(booland, n_notEmpties);
   endfunction

   FIFOF#(Bool) checkFifo <- mkFIFOF();
   rule check if (verbose);
      let v <- toGet(checkFifo).get();
      LUInt#(max_out) rot = i_max_out - extend(outPos);
      Vector#(max_out, Bool) allNotEmpties = map(fifoNotEmpty, fifos);
      Vector#(max_out, Bool) notEmpties = rotateBy(map(fifoNotEmpty, fifos), truncate(rot));
      if (verbose)
      $display("check outPos: ", outPos, " notEmpty: ", fifos[outPos].notEmpty(),
	 " notEmpties: ", notEmpties, " allNotEmpties: %h", allNotEmpties);
   endrule

   function PipeIn#(Vector#(n_in, t)) genInPipe(Integer i);
      return (interface PipeIn#(Vector#(n_in, t))
		 method Action enq(Vector#(n_in, t) data);
		    function Bool lessThanCount(Integer i); return fromInteger(i) < i_n_in; endfunction
		    Vector#(max_out, Bool) we = genWith(lessThanCount);
		    Vector#(max_out, t) wdata = append(data, replicate(?));
		    inFifo.enq(rotateBy(wdata, inPos));
		    posFifo.enq(inPos);
		    weFifo.enq(pack(rotateBy(we, inPos)));
		    inPos <= truncate((extend(inPos) + extend(i_n_in)) % i_max_out);

		    if (verbose) begin
		       $display("enq: inPos=%d we=%h", inPos, we);
		    end
		 endmethod
		 method notFull = inFifo.notFull;
	      endinterface);
   endfunction

   function PipeOut#(Vector#(max_out, t)) genOutPipe(Integer n_out);
      function t firstN(Integer i);
	 if (i < n_out)
	    return fifos[(extend(outPos) + fromInteger(i)) % i_max_out].first;
	 else
	    return ?;
      endfunction

      PipeOut#(Vector#(max_out, t)) pipeOut =
        (interface PipeOut#(Vector#(max_out, t))
	    method    Vector#(max_out, t)           first if (deqReadyInternal(n_out));
	       return genWith(firstN);
	    endmethod

	    method    Action                      deq() if (deqReadyInternal(n_out));
	       for (Integer i = 0; i < n_out; i = i+1)
		  fifos[(extend(outPos) + fromInteger(i)) % i_max_out].deq();
	       UInt#(max_out_sz) nextOutPos = truncate((extend(outPos) + fromInteger(valueOf(max_out))) % i_max_out);
	       outPos <= nextOutPos;

	       if (verbose) begin
		  LUInt#(max_out) rot = i_max_out - extend(outPos);
		  Vector#(max_out, t) v = genWith(firstN);
		  Vector#(max_out, Bool) allNotEmpties = rotateBy(map(fifoNotEmpty, fifos), truncate(rot));
		  Vector#(max_out, Bool) notEmpties = map(fifoNotEmpty, rotateBy(fifos, truncate(rot)));
		  $display("first: ", v, " outPos: ", outPos, " nextOutPos: ", nextOutPos, " nextNotEmpty: ", fifos[nextOutPos].notEmpty(),
		     " notEmpties: ", notEmpties, " allNotEmpties: %h", allNotEmpties);
		  checkFifo.enq(True);
	       end
	    endmethod
      
	    method notEmpty  = deqReadyInternal(n_out);
	 endinterface);
      return pipeOut;
   endfunction

   interface Vector in = genInPipe(0);
   interface Vector out = genWith(genOutPipe);
endmodule
