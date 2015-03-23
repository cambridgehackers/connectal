
// Copyright (c) 2013 Nokia, Inc.
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

import FIFO::*;
import PipeMul::*;

interface PipeMulIndication;
    method Action res(Bit#(64) v);
endinterface

interface PipeMulRequest;
   method Action mul(Bit#(32) x, Bit#(32) y);
endinterface

interface PipeMulTB;
   interface PipeMulRequest ifc;
endinterface

(* synthesize *)
module mkPipeMul2Synth(PipeMul2#(2,24,void));
   let pm <- mkPipeMul2();
   return pm;
endmodule

module mkPipeMulTB#(PipeMulIndication indication)(PipeMulTB);
   PipeMul2#(2,24,void) multiplier <- mkPipeMul2Synth;
   rule res;
      match {.rv, .*} <- multiplier.get;
      indication.res(extend(pack(rv)));
   endrule
   interface PipeMulRequest ifc;
      method Action mul(Bit#(32) a, Bit#(32) b);
	 multiplier.put(unpack(truncate(a)),unpack(truncate(b)),?);
      endmethod
   endinterface
endmodule
