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
import Bounce::*;
`ifdef RedefInstance
import `RedefInstance::*;
`endif
import Pipe::*;

interface EchoIndication;
    method Action heard(Bit#(32) v);
    method Action heard2(Bit#(16) a, Bit#(16) b);
endinterface

interface EchoRequest;
   method Action say(Bit#(32) v);
   method Action say2(Bit#(16) a, Bit#(16) b);
   method Action setLeds(Bit#(8) v);
endinterface

interface Echo;
   interface EchoRequest request;
endinterface

module mkEcho#(EchoIndication indication)(Echo);
    Bounce bounce <- mkBounce();

    rule heard;
        bounce.outDelay.deq();
        indication.heard(bounce.outDelay.first);
    endrule

    rule heard2;
        bounce.outPair.deq();
        indication.heard2(bounce.outPair.first.b, bounce.outPair.first.a);
    endrule
   
   interface EchoRequest request;
      method Action say(Bit#(32) v);
	 bounce.inDelay.enq(v);
      endmethod
      
      method Action say2(Bit#(16) a, Bit#(16) b);
	 bounce.inPair.enq(EchoPair { a: a, b: b});
      endmethod
      
      method Action setLeds(Bit#(8) v);
      endmethod
   endinterface
endmodule
