
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

`include "ConnectalProjectConfig.bsv"
import BviFpAdd::*;
import Clocks::*;
import GetPut::*;
import ClientServer::*;
import FloatingPoint::*;
import FIFO::*;

`ifdef SIMULATION

module mkXilinxFPAdder(Server#(Tuple2#(Float,Float), Float));

   FIFO#(Float) resultFifo <- mkFIFO();

   interface Put request;
      method Action put(Tuple2#(Float,Float) req);
	 match { .a, .b } = req;
	 resultFifo.enq(a+b);
      endmethod
   endinterface
   interface Get response = toGet(resultFifo);

endmodule: mkXilinxFPAdder

`else
module mkXilinxFPAdder(Server#(Tuple2#(Float,Float), Float));
   let fpAdd <- mkBviFpAdd();
   
   interface Put request;
   method Action put(Tuple2#(Float,Float) req);
      match { .a, .b } = req;
      fpAdd.s_axis_a(a);
      fpAdd.s_axis_b(b);
      fpAdd.s_axis_operation(0);
   endmethod
   endinterface
   
   interface Get response = toGet(fpAdd.m_axis_result);
endmodule
`endif
