// Copyright (c) 2015 The Connectal Project

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
import FIFOF::*;
import Pipe::*;
import Bounce::*;

(* synthesize *)
module mkBounce(Bounce);
    FIFOF#(Bit#(32)) delay <- mkSizedFIFOF(8);
    FIFOF#(EchoPair) delay2 <- mkSizedFIFOF(8);

    interface outDelay = toPipeOut(delay);
    interface PipeIn inDelay;
        method Action enq(Bit#(32) v);
            delay.enq(v + 32);
        endmethod
        method Bool notFull();
            return delay.notFull;
        endmethod
    endinterface
    interface outPair = toPipeOut(delay2);
    interface PipeIn inPair;
        method Action enq(EchoPair v);
            delay2.enq(EchoPair {b:v.a, a:v.b});
        endmethod
        method Bool notFull();
            return delay2.notFull;
        endmethod
    endinterface
endmodule
