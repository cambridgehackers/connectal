
// Copyright (c) 2013 Nokia, Inc.

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

typedef struct{
   Bit#(32) a;
   Bit#(32) b;
   } S1 deriving (Bits);

typedef struct{
   Bit#(8) a;
   Bit#(32) b;
   Bit#(16) c;
   } S2 deriving (Bits);

interface EchoIndications;
    method Action heard1(Bit#(32) v);
    method Action heard2(Bit#(16) a, Bit#(16) b);
    method Action heard3(S1 v);
    method Action heard4(S2 v);
endinterface

interface Echo;
    method Action say1(Bit#(32) v);
    method Action say2(Bit#(16) a, Bit#(16) b);
    method Action say3(S1 v);
    method Action say4(S2 v);
endinterface

module mkEcho#(EchoIndications indications)(Echo);
   let delay1 <- mkSizedFIFO(8);
   let delay2 <- mkSizedFIFO(8);
   let delay3 <- mkSizedFIFO(8);
   let delay4 <- mkSizedFIFO(8);
   
   rule heard1;
      delay1.deq;
      indications.heard1(delay1.first);
   endrule
   
   rule heard2;
      delay2.deq;
      match {.a, .b} = delay2.first;
      indications.heard2(a,b);
   endrule
   
   rule heard3;
      delay3.deq;
      indications.heard3(delay3.first);
   endrule
   
   rule heard4;
      delay4.deq;
      indications.heard4(delay4.first);
   endrule

   method Action say1(Bit#(32) v);
      delay1.enq(v);
   endmethod

   method Action say2(Bit#(16) a, Bit#(16) b);
      delay2.enq(tuple2(a,b));
   endmethod
   
   method Action say3(S1 v);
      delay3.enq(v);
   endmethod

   method Action say4(S2 v);
      delay4.enq(v);
   endmethod
   
endmodule