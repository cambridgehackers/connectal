
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
    method Action heard5(Bit#(32) a, Bit#(64) b, Bit#(32) c);
    method Action heard6(Bit#(32) a, Bit#(40) b, Bit#(32) c);
endinterface

interface CoreRequest;
    method Action say1(Bit#(32) v);
    method Action say2(Bit#(16) a, Bit#(16) b);
    method Action say3(S1 v);
    method Action say4(S2 v);
    method Action say5(Bit#(32)a, Bit#(64) b, Bit#(32) c);
    method Action say6(Bit#(32)a, Bit#(40) b, Bit#(32) c);
endinterface

interface StructRequest;
   interface CoreRequest coreRequest;
endinterface

interface StructIndication;
   interface CoreIndication coreIndication;
endinterface

typedef struct {
    Bit#(32) a;
    Bit#(40) b;
    Bit#(32) c;
} Say6ReqStruct deriving (Bits);


module mkStructRequest#(StructIndication indication)(StructRequest);

   interface CoreRequest coreRequest; 
   method Action say1(Bit#(32) v);
      indication.coreIndication.heard1(v);
      $display("(hw) say1 %d", v);
   endmethod
   
   method Action say2(Bit#(16) a, Bit#(16) b);
      indication.coreIndication.heard2(a,b);
      $display("(hw) say2 %d %d", a, b);
   endmethod
      
   method Action say3(S1 v);
      indication.coreIndication.heard3(v);
      $display("(hw) say3 S1{a:%d, b:%d}", v.a, v.b);
   endmethod
   
   method Action say4(S2 v);
      indication.coreIndication.heard4(v);
      $display("(hw) say4 S1{a:%d, b:%d, c:%d}", v.a, v.b, v.c);
   endmethod
      
   method Action say5(Bit#(32) a, Bit#(64) b, Bit#(32) c);
      indication.coreIndication.heard5(a, b, c);
      $display("(hw) say5 %h %h %h", a, b, c);
   endmethod

   method Action say6(Bit#(32) a, Bit#(40) b, Bit#(32) c);
      indication.coreIndication.heard6(a, b, c);
      $display("(hw) say6 %h %h %h", a, b, c);
      // Say6ReqStruct rs = Say6ReqStruct{a:32'hBBBBBBBB, b:40'hEFFECAFECA, c:32'hCCCCCCCC};
      // $display("(hw) say6 %h", pack(rs));
      // indication.coreIndication.heard6(rs.a, rs.b, rs.c);
   endmethod
   endinterface

endmodule