
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

interface EchoIndicationSW;
    method Action heard(Bit#(32) v);
    method Action heard2(Bit#(16) a, Bit#(16) b);
endinterface

interface EchoRequestSW;
   method Action say(Bit#(32) v);
   method Action say2(Bit#(16) a, Bit#(16) b);
   method Action setLeds(Bit#(8) v);
endinterface

interface EchoIndication;
    method Action heard(Bit#(32) id, Bit#(32) v);
    method Action heard2(Bit#(32) id, Bit#(16) a, Bit#(16) b);
endinterface

interface EchoRequest;
   method Action say(Bit#(32) id, Bit#(32) v);
   method Action say2(Bit#(32) id, Bit#(16) a, Bit#(16) b);
   method Action setLeds(Bit#(32) id, Bit#(8) v);
endinterface

interface Echo;
   interface EchoRequest request;
endinterface

typedef struct {
	Bit#(32) id;
	Bit#(32) v;
} EchoPair1 deriving (Bits);

typedef struct {
	Bit#(32) id;
	Bit#(16) a;
	Bit#(16) b;
} EchoPair2 deriving (Bits);

module mkEcho#(EchoIndication indication)(Echo);

    FIFO#(EchoPair1) delay1 <- mkSizedFIFO(8);
    FIFO#(EchoPair2) delay2 <- mkSizedFIFO(8);

    rule heard;
        delay1.deq;
        indication.heard(delay1.first.id, delay1.first.v);
    endrule

    rule heard2;
        delay2.deq;
        indication.heard2(delay2.first.id, delay2.first.b, delay2.first.a);
    endrule
   
   interface EchoRequest request;
      method Action say(Bit#(32) id, Bit#(32) v);
	 delay1.enq(EchoPair1 { id: id, v: v});
      endmethod
      
      method Action say2(Bit#(32) id, Bit#(16) a, Bit#(16) b);
	 delay2.enq(EchoPair2 { id: id, a: a, b: b});
      endmethod
      
      method Action setLeds(Bit#(32) id, Bit#(8) v);
      endmethod
   endinterface
endmodule
