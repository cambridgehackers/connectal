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


import Gearbox :: *;
import Pipe :: *;

interface SerialFIFO#(type a);
   interface PipeIn#(a) in;
   interface PipeOut#(a) out;
endinterface

module mkSerialFIFO(SerialFIFO#(a))
   provisos(Bits#(a, asize),
	    Add#(1,a__,TMul#(2,asize)),
	    Add#(asize,b__,TMul#(2,asize)),
	    Add#(1, c__, asize));

   
   Clock clk <- exposeCurrentClock;
   Reset rst <- exposeCurrentReset;

   Gearbox#(asize, 1, Bit#(1)) gin <- mkNto1Gearbox(clk,rst,clk,rst);
   Gearbox#(1, asize, Bit#(1)) gout <- mk1toNGearbox(clk,rst,clk,rst);
   
   rule movebits;
      gout.enq(gin.first);
      gin.deq();
   endrule
   
   interface PipeIn in;
      
      method Action enq(a din);
	 gin.enq(unpack(pack(din)));
      endmethod
      
      method Bool notFull() = gin.notFull;
      
   endinterface
   
   interface PipeOut out;
   
      method a first();
	 return(unpack(pack(gout.first)));
      endmethod
      
      method Action deq() = gout.deq;
   
      method Bool notEmpty() = gout.notEmpty;
      
   endinterface
   
endmodule