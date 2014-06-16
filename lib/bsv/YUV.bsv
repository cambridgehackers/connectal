
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

import Vector::*;
import Arith::*;

// little endian RGB
typedef struct {
    Bit#(8) r;
    Bit#(8) b;
    Bit#(8) g;
} Rgb888 deriving (Bits);

typedef struct {
    Bit#(1) vsync;
    Bit#(1) hsync;
    Bit#(1) de;
    pixelType pixel;
} VideoData#(type pixelType) deriving (Bits);

typedef struct {
    Bit#(8) y;
    Bit#(8) u;
    Bit#(8) v;
} Yuv444 deriving (Bits);

typedef struct {
    Bit#(8) y1;
    Bit#(8) u;
    Bit#(8) y2;
    Bit#(8) v;
} Yuv422 deriving (Bits);

typedef struct {
    Bit#(8) uv;
    Bit#(8) yy;
} Yyuv deriving (Bits);

interface Rgb888ToYuv422;
    method Action putRgb888(Rgb888 rgb888);
    method ActionValue#(Yuv422) getYuv422();
endinterface

function Yuv444 rgbtoyuv(Rgb888 rgb);
    Bit#(16) y = 77*extend(rgb.r) + 150 * extend(rgb.g) + 29 * extend(rgb.b) + 0;
    Bit#(16) u = -43*extend(rgb.r) - 85*extend(rgb.g) + 128*extend(rgb.b) + 128;
    Bit#(16) v = 128*extend(rgb.r) - 107*extend(rgb.g) - 21*extend(rgb.b) + 128;
    return Yuv444 { y: truncate(y>>8), u: truncate(u >> 8), v: truncate(v >> 8) };
endfunction

typedef Vector#(4, Vector#(3, Bit#(16))) Yuv444Intermediates;

function Vector#(3, Bit#(n)) rgbToVector(Rgb888 rgb) provisos (Add#(a__, 8, n));
   Vector#(3, Bit#(n)) vec;
   vec[0] = zeroExtend(rgb.r);
   vec[1] = zeroExtend(rgb.g);
   vec[2] = zeroExtend(rgb.b);
   return vec;
endfunction   
function Yuv444 yuv444FromVector(Vector#(3, Bit#(n)) vec) provisos (Add#(a__, 8, n));
   return Yuv444 { y: truncate(vec[0]), u: truncate(vec[1]), v: truncate(vec[2]) };
endfunction

function Yuv444Intermediates rgbToYuvIntermediates(Rgb888 rgb);
   Vector#(3, Vector#(4, Bit#(16))) rgbv = replicate(append(rgbToVector(rgb), replicate(1)));
   Vector#(3, Vector#(4, Bit#(16))) coeffs = replicate(newVector());
   coeffs[0][0] =  77; coeffs[0][1] =  150; coeffs[0][2] =  29; coeffs[0][3] = 0;
   coeffs[1][0] = -43; coeffs[1][1] =  -85; coeffs[1][2] = 128; coeffs[1][3] = 128;
   coeffs[2][0] = 128; coeffs[2][1] = -107; coeffs[2][2] = -21; coeffs[2][3] = 128;
   return transpose(map(uncurry(vmul), zip(rgbv, coeffs)));
endfunction

function Yuv444 yuvIntermediatesToYuv444(Yuv444Intermediates w);
   Vector#(3, Bit#(16)) v0 = vadd(w[0], w[1]);
   Vector#(3, Bit#(16)) v1 = vadd(w[2], w[3]);
   return yuv444FromVector(vrshift(vadd(vadd(w[0], w[1]), vadd(w[2], w[3])), 8));
endfunction

function Yuv422 yuv444toyuv422(Yuv444 yuv0, Yuv444 yuv1);
    Bit#(9) u = (extend(yuv0.u) + extend(yuv1.u)) >> 1;
    Bit#(9) v = (extend(yuv0.u) + extend(yuv1.v)) >> 1;
    return Yuv422 { y1: yuv0.y, u: truncate(u), y2: yuv1.y, v: truncate(v) };
endfunction
