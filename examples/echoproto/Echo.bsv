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
import Vector::*;
import EchoRequest::*;
import EchoIndication::*;
import GeneratedTypes::*;

interface Echo;
   interface EchoRequest request;
endinterface

module mkEcho#(EchoIndication indication)(Echo);
    FIFO#(EchoHeard) delay <- mkSizedFIFO(8);
    FIFO#(EchoHeard2) delay2 <- mkSizedFIFO(8);

    rule heard;
        delay.deq;
        indication.heard(delay.first);
    endrule

    rule heard2;
        delay2.deq;
        indication.heard2(delay2.first);
    endrule
   
   interface EchoRequest request;
      method Action say(EchoSay v);
	 delay.enq(EchoHeard{v: v.v});
      endmethod
      
      method Action say2(EchoSay2 v);
	 delay2.enq(EchoHeard2{ a: v.a, b: v.b});
      endmethod
      
      method Action setLeds(EchoLeds v);
      endmethod
   endinterface
endmodule
