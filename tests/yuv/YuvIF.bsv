
// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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

import GetPut::*;
import HDMI::*;
import Vector::*;
import Arith::*;
import YUV::*;

interface YuvRequest;
   method Action toRgb(Bit#(8) r, Bit#(8) g, Bit#(8) b);
   method Action toYuv(Bit#(8) r, Bit#(8) g, Bit#(8) b);
   method Action toYyuv(Bit#(8) r, Bit#(8) g, Bit#(8) b);
endinterface

interface YuvIndication;
   method Action rgb(Bit#(8) y, Bit#(8) u, Bit#(8) v);
   method Action yuv(Bit#(8) y, Bit#(8) u, Bit#(8) v);
   method Action yyuv(Bit#(8) yy, Bit#(8) uv);
endinterface

interface YuvIF;
  interface YuvRequest request;
endinterface

module mkYuvIF#(YuvIndication indication)(YuvIF);
   let rgb888ToYyuv <- mkRgb888ToYyuv();
   
    Wire#(VideoData#(Rgb888))                    yyuvInputWire <- mkDWire(unpack(0));
    Wire#(VideoData#(Rgb888))                        stage0Reg <- mkDWire(unpack(0));
    Reg#(VideoData#(Yuv444Intermediates))            stage1Reg <- mkReg(unpack(0));
    Reg#(VideoData#(Vector#(2,Vector#(3,Bit#(16))))) stage2Reg <- mkReg(unpack(0));
    Reg#(VideoData#(Yuv444))                         stage3Reg <- mkReg(unpack(0));
    Reg#(VideoData#(Yyuv))                           stage4Reg <- mkReg(unpack(0));
    Reg#(Bool) evenOddPixelReg <- mkReg(False);
   
    rule stage1_rule;
        let previous = stage0Reg;
        let pixel = previous.pixel;
        stage1Reg <= VideoData {
            vsync: previous.vsync, hsync: previous.hsync, de: previous.de,
            pixel: (previous.de != 0) ? rgbToYuvIntermediates(pixel) : unpack(0)
        };
    endrule

    rule stage2_rule;
        let previous = stage1Reg;
       Vector#(4, Vector#(3, Bit#(16))) vprev = previous.pixel;
       Vector#(2, Vector#(3, Bit#(16))) vnext;
       vnext[0] = vadd(vprev[0], vprev[1]);
       vnext[1] = vadd(vprev[2], vprev[3]);

       stage2Reg <= VideoData {
            vsync: previous.vsync, hsync: previous.hsync, de: previous.de,
	    pixel: (previous.de != 0) ? vnext : unpack(0)
        };
    endrule

   rule stage3_rule;
      let previous = stage2Reg;
       Vector#(2, Vector#(3, Bit#(16))) vprev = previous.pixel;
      Yuv444 pixel = yuv444FromVector(vrshift(vadd(vprev[0], vprev[1]), 8));

      stage3Reg <= VideoData {
            vsync: previous.vsync, hsync: previous.hsync, de: previous.de,
	 pixel: (previous.de != 0) ? pixel : unpack(0) };
   endrule

   rule yuv_rule;
      let v = stage3Reg;
      if (v.de == 1)
	 indication.yuv(v.pixel.y, v.pixel.u, v.pixel.v);
   endrule

   rule yyuv_input_rule;
      rgb888ToYyuv.rgb888.put(yyuvInputWire);
   endrule
   rule yyuv_rule;
      let v <- rgb888ToYyuv.yyuv.get();
      if (v.de == 1)
	 indication.yyuv(v.pixel.yy, v.pixel.uv);
   endrule

   interface YuvRequest request;
   method Action toRgb(Bit#(8) r, Bit#(8) g, Bit#(8) b);
      indication.rgb(r, g, b);
   endmethod
   method Action toYuv(Bit#(8) r, Bit#(8) g, Bit#(8) b);
      stage0Reg <= VideoData { de: 1, vsync: 0, hsync: 0, pixel: Rgb888 { r:r, g:g, b:b } };
   endmethod
   
   method Action toYyuv(Bit#(8) r, Bit#(8) g, Bit#(8) b);
      yyuvInputWire <= VideoData { de: 1, vsync: 0, hsync: 0, pixel: Rgb888 { r:r, g:g, b:b } };
   endmethod
   endinterface

endmodule
