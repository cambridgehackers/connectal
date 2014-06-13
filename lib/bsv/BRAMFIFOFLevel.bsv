// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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


import GetPut::*;
import BRAMFIFO::*;
import FIFOF::*;

interface Counter#(numeric type count_sz);
   method Action reset();
   method Action increment();
   method Action decrement();
   method Bit#(count_sz) read();
endinterface

module mkCounter#(Bit#(count_sz) init_val)(Counter#(count_sz));
   PulseWire inc_wire <- mkPulseWire;
   PulseWire dec_wire <- mkPulseWire;
   PulseWire rst_wire <- mkPulseWire;
   Reg#(Bit#(count_sz)) cnt <- mkReg(init_val);
   (* fire_when_enabled *)
   rule react;
      if (rst_wire)
	 cnt <= 0;
      else if (inc_wire && dec_wire)
	 noAction;
      else if (inc_wire)
	 cnt <= cnt+1;
      else if (dec_wire)
	 cnt <= cnt-1;
      else
	 noAction;
   endrule
   method Action increment = inc_wire.send;
   method Action decrement = dec_wire.send;
   method Action reset = rst_wire.send;
   method Bit#(count_sz) read = cnt._read;
endmodule

interface FIFOFLevel#(type element_type, numeric type fifo_depth);
   interface FIFOF#(element_type) fifo;
   method Bool highWater(Bit#(TAdd#(1,TLog#(fifo_depth))) mark);
   method Bool lowWater(Bit#(TAdd#(1,TLog#(fifo_depth))) mark);
endinterface

instance ToGet#(FIFOFLevel#(a,b), a);
   function Get#(a) toGet(FIFOFLevel#(a,b) f) = toGet(f.fifo);
endinstance

instance ToPut#(FIFOFLevel#(a,b), a);
   function Put#(a) toPut(FIFOFLevel#(a,b) f) = toPut(f.fifo);
endinstance

module mkBRAMFIFOFLevel(FIFOFLevel#(element_type, fifo_depth))
   provisos(Log#(fifo_depth, log_fifo_depth),
	    Add#(log_fifo_depth,1,mark_width),
	    Bits#(element_type, __a),
	    Add#(1, a__, __a));

   Counter#(mark_width) cnt <- mkCounter(0);
   FIFOF#(element_type) fif <- mkSizedBRAMFIFOF(valueOf(fifo_depth));
   
   method Bool highWater(Bit#(mark_width) mark);
      return (cnt.read >= mark);
   endmethod
   
   method Bool lowWater(Bit#(mark_width) mark);
      return (fromInteger(valueOf(fifo_depth))-cnt.read >= mark);
   endmethod
  
   interface FIFOF fifo;
      method Action enq (element_type x);
	 cnt.increment;
	 fif.enq(x);
      endmethod
      method Action deq;
	 cnt.decrement;
	 fif.deq;
      endmethod
      method Action clear;
	 cnt.reset;
	 fif.clear;
      endmethod
      method element_type first = fif.first;
      method Bool notFull = fif.notFull;
      method Bool notEmpty = fif.notEmpty;
   endinterface
   
endmodule

module mkFIFOFLevel(FIFOFLevel#(element_type, fifo_depth))
   provisos(Log#(fifo_depth, log_fifo_depth),
	    Add#(log_fifo_depth,1,mark_width),
	    Bits#(element_type, __a),
	    Add#(1, a__, __a));

   Counter#(mark_width) cnt <- mkCounter(0);
   FIFOF#(element_type) fif <- mkSizedFIFOF(valueOf(fifo_depth));

   method Bool highWater(Bit#(mark_width) mark);
      return (cnt.read >= mark);
   endmethod

   method Bool lowWater(Bit#(mark_width) mark);
      return (fromInteger(valueOf(fifo_depth))-cnt.read >= mark);
   endmethod

   interface FIFOF fifo;
      method Action enq (element_type x);
	 cnt.increment;
	 fif.enq(x);
      endmethod
      method Action deq;
	 cnt.decrement;
	 fif.deq;
      endmethod
      method Action clear;
	 cnt.reset;
	 fif.clear;
      endmethod
      method element_type first = fif.first;
      method Bool notFull = fif.notFull;
      method Bool notEmpty = fif.notEmpty;
   endinterface

endmodule
