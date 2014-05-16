
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

import BviFpAdd::*;
import Clocks::*;
import GetPut::*;
import ClientServer::*;
import FloatingPoint::*;

module mkXilinxFPAdder(Server#(Tuple2#(Float,Float), Float));
   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   let fpAdd <- mkBviFpAdd(clock, reset);
   Wire#(Bit#(1)) s_axis_ab_ready <- mkDWire(0);
   Wire#(Bit#(1)) m_axis_tready <- mkDWire(0);
   rule ab_ready;
      fpAdd.s_axis_a.tvalid(s_axis_ab_ready);
      fpAdd.s_axis_b.tvalid(s_axis_ab_ready);
   endrule
   rule c_ready;
      fpAdd.m_axis_result.tready(m_axis_tready);
   endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface Put request;
      method Action put(Tuple2#(Float,Float) req) if (fpAdd.s_axis_a.tready() == 1 && fpAdd.s_axis_b.tready() == 1);
	 match { .a, .b } = req;
	 fpAdd.s_axis_a.tdata(pack(a));
	 fpAdd.s_axis_b.tdata(pack(b));
	 s_axis_ab_ready <= 1;
      endmethod
   endinterface
   interface Get response;
      method ActionValue#(Float) get() if (fpAdd.m_axis_result.tvalid() == 1);
	 m_axis_tready <= 1;
	 return unpack(fpAdd.m_axis_result.tdata());
      endmethod
   endinterface

endmodule: mkXilinxFPAdder

