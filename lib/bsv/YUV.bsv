
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

// little endian RGB
typedef struct {
    Bit#(8) b;
    Bit#(8) g;
    Bit#(8) r;
} Rgb888 deriving (Bits);

typedef struct {
    Bit#(1) vsync;
    Bit#(1) hsync;
    Bit#(1) active_video;
    Bit#(8) r;
    Bit#(8) g;
    Bit#(8) b;
} Rgb888VideoData deriving (Bits);

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

typedef struct {
    Bit#(16) y1;
    Bit#(16) y2;
    Bit#(16) y3;
    Bit#(16) u1;
    Bit#(16) u2;
    Bit#(16) u3;
    Bit#(16) v1;
    Bit#(16) v2;
    Bit#(16) v3;
} Yuv444Intermediates deriving (Bits);

typedef struct {
    Bit#(1) vsync;
    Bit#(1) hsync;
    Bit#(1) de;
    Rgb888 pixel;
} Rgb888Stage deriving (Bits);

typedef struct {
    Bit#(1) vsync;
    Bit#(1) hsync;
    Bit#(1) de;
    Yuv444Intermediates data;
} Yuv444IntermediatesStage deriving (Bits);

typedef struct {
    Bit#(1) vsync;
    Bit#(1) hsync;
    Bit#(1) de;
    Yuv444 data;
} Yuv444Stage deriving (Bits);

typedef struct {
    Bit#(1) vsync;
    Bit#(1) hsync;
    Bit#(1) de;
    Bit#(16) data;
} Yuv422Stage deriving (Bits);

function Yuv444Intermediates rgbToYuvIntermediates(Rgb888 rgb);
    return Yuv444Intermediates {
               y1: 77*extend(rgb.r), y2: 150 * extend(rgb.g), y3: 29 * extend(rgb.b),
               u1: 43*extend(rgb.r), u2: 85*extend(rgb.g), u3: 128*extend(rgb.b),
               v1: 128*extend(rgb.r), v2: 107*extend(rgb.g), v3: 21*extend(rgb.b) };
endfunction

function Yuv444 yuvIntermediatesToYuv444(Yuv444Intermediates w);
    let y = 0 + w.y1 + w.y2 + w.y3;
    let u = (128<<8) - w.u1 -w.u2 + w.u3;
    let v = (128<<8) + w.v1 - w.v2 - w.v3;
    return Yuv444 { y: truncate(y>>8), u: truncate(u >> 8), v: truncate(v >> 8) };
endfunction

function Yuv422 yuv444toyuv422(Yuv444 yuv0, Yuv444 yuv1);
    Bit#(9) u = (extend(yuv0.u) + extend(yuv1.u)) >> 1;
    Bit#(9) v = (extend(yuv0.u) + extend(yuv1.v)) >> 1;
    return Yuv422 { y1: yuv0.y, u: truncate(u), y2: yuv1.y, v: truncate(v) };
endfunction



// module mkRgb888ToYuv422(Rgb888ToYuv422);
//     FIFOF#(Yuv444) yuvFifo <- mkBypassFIFOF();
//     Reg#(Maybe#(Yuv444)) yuvReg1 <- mkReg(tagged Invalid);

//     rule alternating if (yuvReg1 matches tagged Invalid);
//         yuvReg1 <= tagged Valid yuv0;
//     endrule

//     method Action putRgb888(Rgb888 rgb888) if (yuvReg0 matches tagged Invalid);
//         yuvFifo.enq(rgbtoyub(rgb888));
//     endmethod

//     method ActionValue#(Yuv422) getYuv422() if (yuvReg1 matches tagged Valid .yuv1);
//         let yuv0 = yuvFifo.first;
//         yuvFifo.deq;
//         let yuv1 = yuvReg1;
//         yuvReg1 <= tagged Invalid;
//         let yuv422 = yuv444toyuv422(yuv0, yuv1);
//         return yuv422;
//     endmethod

// endmodule
