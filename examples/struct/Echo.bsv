
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
   Bit#(32) a;
   Bit#(16) b;
   Bit#(16) c;
   } S2 deriving (Bits);

interface CoreIndication;
    method Action heard1(Bit#(32) v);
    method Action heard2(Bit#(16) a, Bit#(16) b);
    method Action heard3(S1 v);
    method Action heard4(S2 v);
    method Action heard5(Bit#(32) _x, Bit#(64) v, Bit#(32) _y);
endinterface

interface CoreRequest;
    method Action say1(Bit#(32) v);
    method Action say2(Bit#(16) a, Bit#(16) b);
    method Action say3(S1 v);
    method Action say4(S2 v);
    method Action say5(Bit#(32)_x, Bit#(64) v, Bit#(32) _y);
endinterface

interface EchoRequest;
   interface CoreRequest coreRequest;
endinterface

interface EchoIndication;
   interface CoreIndication coreIndication;
endinterface

module mkEchoRequest#(EchoIndication indication)(EchoRequest);

   interface CoreRequest coreRequest; 
   method Action say1(Bit#(32) v);
      indication.coreIndication.heard1(v);
      $display("(hw) say1 %h", v);
   endmethod
   
   method Action say2(Bit#(16) a, Bit#(16) b);
      indication.coreIndication.heard2(a+1,b);
      $display("(hw) say2 %h %h", a, b);
   endmethod
      
   method Action say3(S1 v);
      S1 rv = S1{a:v.a, b:v.b+1};
      indication.coreIndication.heard3(rv);
      $display("(hw) say3 %h", v);
   endmethod
   
   method Action say4(S2 v);
      S2 rv = S2{a:v.a+2, b:v.b+1, c:v.c};
      indication.coreIndication.heard4(rv);
      $display("(hw) say4 %h", v);
   endmethod
      
   method Action say5(Bit#(32) _x, Bit#(64) v, Bit#(32) _y);
      //indication.coreIndication.heard5(_x, {v[63:4],4'h0}, _y);
      indication.coreIndication.heard5(_x, 64'h5a5a5a5a5a5a5a5a, _y);
      $display("(hw) say5 %h %h %h", _x, v, _y);
   endmethod
   endinterface

endmodule