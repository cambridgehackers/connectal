
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
import Vector::*;

typedef struct{
   Bit#(32) a;
   Bit#(32) b;
   } S1 deriving (Bits);

typedef struct{
   Bit#(32) a;
   Bit#(16) b;
   Bit#(7) c;
   } S2 deriving (Bits);

typedef enum {
   E1Choice1,
   E1Choice2,
   E1Choice3
   } E1 deriving (Bits,Eq);

typedef struct{
   Bit#(32) a;
   E1 e1;
   } S3 deriving (Bits);

typedef Bit#(24) Address;
typedef Bit#(32) Intptr;
typedef Bit#(8) Byte;

interface SimpleRequest;
    method Action say1(Bit#(32) v);
    method Action say2(Bit#(16) a, Bit#(16) b);
    method Action say3(S1 v);
    method Action say4(S2 v);
    method Action say5(Bit#(32)a, Bit#(64) b, Bit#(32) c);
    method Action say6(Bit#(32)a, Bit#(40) b, Bit#(32) c);
    method Action say7(S3 v);
    method Action say8(Vector#(128, Bit#(32)) v);
    method Action sayv1 (Vector#(4, Int#(32)) arg1, Vector#(4, Int#(32)) arg2);
    method Action sayv2 (Vector#(16, Int#(16)) v);
    method Action sayv3 (Vector#(16, Int#(16)) v, Int#(16) count);
    method Action saypixels(Vector#(2, Bit#(32)) xs, Vector#(2, Bit#(32)) ys, Vector#(2, Bit#(32)) zs);
    method Action reftest1(Address dst, Intptr dst_stride,
              Address src1, Intptr i_src_stride1,
              Address src2, Intptr i_src_stride2,
              Byte i_width, Byte i_height, Bool qpelInt,
              Bool hasWeight, Byte i_offset, Byte i_scale, Byte i_denom);
endinterface

typedef struct {
    Bit#(32) a;
    Bit#(40) b;
    Bit#(32) c;
} Say6ReqSimple deriving (Bits);

interface Simple;
    interface SimpleRequest request;
endinterface

module mkSimple#(SimpleRequest indication)(Simple);
   let verbose = False;

   interface SimpleRequest request;
   method Action say1(Bit#(32) v);
      if (verbose) $display("mkSimple::say1");
      indication.say1(v);
   endmethod

   method Action say2(Bit#(16) a, Bit#(16) b);
      if (verbose) $display("mkSimple::say2");
      indication.say2(a,b);
   endmethod

   method Action say3(S1 v);
      if (verbose) $display("mkSimple::say3");
      indication.say3(v);
   endmethod

   method Action say4(S2 v);
      if (verbose) $display("mkSimple::say4");
      indication.say4(v);
   endmethod

   method Action say5(Bit#(32) a, Bit#(64) b, Bit#(32) c);
      if (verbose) $display("mkSimple::say5");
      indication.say5(a, b, c);
   endmethod

   method Action say6(Bit#(32) a, Bit#(40) b, Bit#(32) c);
      if (verbose) $display("mkSimple::say6");
      indication.say6(a, b, c);
   endmethod

   method Action say7(S3 v);
      if (verbose) $display("mkSimple::say7");
      indication.say7(v);
   endmethod

   method Action say8(Vector#(128, Bit#(32)) v);
      if (verbose) $display("mkSimple::say8");
      indication.say8(v);
   endmethod
   method Action sayv1 (Vector#(4, Int#(32)) arg1, Vector#(4, Int#(32)) arg2);
      if (verbose) $display("mkSimple::sayv1");
      indication.sayv1(arg1, arg2);
   endmethod
   method Action sayv2 (Vector#(16, Int#(16)) v);
      if (verbose) $display("mkSimple::sayv2");
      indication.sayv2(v);
   endmethod
   method Action sayv3 (Vector#(16, Int#(16)) v, Int#(16) count);
      if (verbose) $display("mkSimple::sayv3");
      indication.sayv3(v, count);
   endmethod
    method Action saypixels(Vector#(2, Bit#(32)) xs, Vector#(2, Bit#(32)) ys, Vector#(2, Bit#(32)) zs);
      if (verbose) $display("mkSimple::saypixels");
      indication.saypixels(xs, ys, zs);
   endmethod
   method Action reftest1(Address dst, Intptr dst_stride,
            Address src1, Intptr i_src_stride1,
              Address src2, Intptr i_src_stride2,
              Byte i_width, Byte i_height, Bool qpelInt,
              Bool hasWeight, Byte i_offset, Byte i_scale, Byte i_denom);
      //if (verbose) 
      $display("mkSimple::reftest1 dst %x dst_stride %x src1 %x i_src_stride1 %x src2 %x i_src_stride2 %x i_width %x i_height %x qpelInt %x hasWeight %x i_offset %x i_scale %x i_denom %x\n",
          dst, dst_stride, src1, i_src_stride1, src2, i_src_stride2, i_width, i_height, qpelInt, hasWeight, i_offset, i_scale, i_denom);
      indication.reftest1(dst, dst_stride, src1, i_src_stride1, src2, i_src_stride2, i_width, i_height, qpelInt, hasWeight, i_offset, i_scale, i_denom);
   endmethod
   endinterface
endmodule
