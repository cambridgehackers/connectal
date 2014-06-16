
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
import Clocks::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import GetPut::*;
import SyncBits::*;
import YUV::*;
import Arith::*;

`ifdef ZC706
typedef 24 HdmiBits;
`else
typedef 16 HdmiBits;
`endif

interface HDMI#(type pixelType);
    method Bit#(1) hdmi_vsync;
    method Bit#(1) hdmi_hsync;
    method Bit#(1) hdmi_de;
    method pixelType hdmi_data;
    interface Clock hdmi_clock_if;
    interface Reset deleteme_unused_reset;
endinterface

interface HdmiInternalRequest;
    method Action setTestPattern(Bit#(1) v);
    method Action setPatternColor(Bit#(32) v);
    method Action setDePixel(Bit#(12) width, Bit#(12) porch, Bit#(12) visible, Bit#(12) last, Bit#(12) mid);
    method Action setDeLine(Bit#(11) width, Bit#(11) porch, Bit#(11) visible, Bit#(11) last, Bit#(11) mid);
    method Action waitForVsync(Bit#(32) unused);
endinterface
interface HdmiInternalIndication;
    method Action vsync(Bit#(64) v, Bit#(32) vs);
endinterface

interface HdmiGenerator#(type pixelType);
    interface HdmiInternalRequest control;
    interface Get#(VideoData#(pixelType)) rgb888;
    interface Put#(Bit#(32)) request;
endinterface

module mkHdmiGenerator#(Clock axi_clock, Reset axi_reset,
   SyncPulseIfc vsyncPulse, HdmiInternalIndication indication)(HdmiGenerator#(Rgb888));
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    // 1920 * 1080
    Reg#(Bit#(12)) dePixelEnd <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(12)) dePixelWidth <- mkSyncReg(3, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(12)) dePixelPorch <- mkSyncReg(192, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(12)) dePixelVisible <- mkSyncReg(1920 + 192, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(12)) pixelMidpoint <- mkSyncReg((1920/2) + 192, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(11)) deLineEnd <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(11)) deLineWidth <- mkSyncReg(3, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(11)) deLinePorch <- mkSyncReg(41, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(11)) deLineVisible <- mkSyncReg(1080+41, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(11)) lineMidpoint <- mkSyncReg((1080/2) + 41, axi_clock, axi_reset, defaultClock);
    Vector#(4, Reg#(Bit#(24))) patternRegs <- replicateM(mkSyncReg(24'h00FFFFFF, axi_clock, axi_reset, defaultClock));
    Reg#(Bit#(1)) shadowTestPatternEnabled <- mkSyncReg(1, axi_clock, axi_reset, defaultClock);
    Reg#(Bool) waitingForVsync <- mkSyncReg(False, axi_clock, axi_reset, defaultClock);
    SyncPulseIfc vsyncCountPulse <- mkSyncHandshake(defaultClock, defaultReset, axi_clock);
    SyncPulseIfc sendVsyncIndication <- mkSyncHandshake(defaultClock, defaultReset, axi_clock);

    Reg#(Bit#(11)) lineCount <- mkReg(0);
    Reg#(Bit#(12)) pixelCount <- mkReg(0);
    Reg#(Bit#(1)) patternIndex0 <- mkReg(0);
    Reg#(Bit#(1)) patternIndex1 <- mkReg(0);
    Reg#(Bit#(1)) testPatternEnabled <- mkReg(1);
    Reg#(Bool) dataEnable <- mkReg(False);

    Reg#(VideoData#(Rgb888)) rgb888StageReg <- mkReg(unpack(0));
    Reg#(Bool) evenOddPixelReg <- mkReg(False);

    Reg#(Bit#(32)) underflowCount <- mkReg(0);
    Reg#(Bit#(32)) underflowCountAxi <- mkSyncReg(0, defaultClock, defaultReset, axi_clock);
    Reg#(Bit#(32)) counter <- mkReg(0, clocked_by axi_clock, reset_by axi_reset);
    Reg#(Bit#(32)) vsyncCounter <- mkReg(0, clocked_by axi_clock, reset_by axi_reset);
    Reg#(Bit#(32)) elapsed <- mkReg(0, clocked_by axi_clock, reset_by axi_reset);
    Reg#(Bit#(32)) elapsedVsync <- mkReg(0, clocked_by axi_clock, reset_by axi_reset);
    Reg#(Bit#(32)) zeropixel <- mkReg(0);
    Reg#(Bit#(32)) pixelcount <- mkReg(0);
    Reg#(Bit#(32)) pixelcount2 <- mkReg(0);
    SyncBitIfc#(Bit#(32)) zeropixels <- mkSyncBits(0, defaultClock, defaultReset, axi_clock, axi_reset);
    SyncBitIfc#(Bit#(32)) pixelcounts <- mkSyncBits(0, defaultClock, defaultReset, axi_clock, axi_reset);
    SyncBitIfc#(Bit#(32)) pixelcount2s <- mkSyncBits(0, defaultClock, defaultReset, axi_clock, axi_reset);

    rule zerosyn;
       zeropixels.send(zeropixel);
       pixelcounts.send(pixelcount);
       pixelcount2s.send(pixelcount2);
    endrule

    rule axicyclecount;
       counter <= counter + 1;
    endrule
      
    rule vsyncCount if (vsyncCountPulse.pulse());
       vsyncCounter <= vsyncCounter+1;
    endrule
    rule vsyncReceived if (sendVsyncIndication.pulse());
       elapsed <= counter;
       elapsedVsync <= vsyncCounter;
       indication.vsync({pixelcount2s.read(), zeropixels.read()}, pixelcounts.read());
       //waitingForVsync <= False;
    endrule

    rule init_pattern;
        patternRegs[1] <= 24'h00FF0000; // blue
        patternRegs[2] <= 24'h0000FF00; // green
        patternRegs[3] <= 24'h000000FF; // red
        //patternRegs[1] <= 32'h80ff80ff; // yuv422 white
        //patternRegs[2] <= 32'h2c961596; // yuv422 green
        //patternRegs[3] <= 32'hff1d6b1d; // yuv422 red
    endrule

    rule inc_counters;
        if (lineCount == 0 && pixelCount == 0) begin
	    vsyncCountPulse.send();
            vsyncPulse.send();
            if (waitingForVsync)
	       sendVsyncIndication.send();
            testPatternEnabled <= shadowTestPatternEnabled;
        end
        if (pixelCount == dePixelEnd) begin
           pixelCount <= 0; 
           patternIndex0 <= 0;
           if (lineCount == deLineEnd) begin
               lineCount <= 0;
               patternIndex1 <= 0;
           end
           else begin
               lineCount <= lineCount+1;
               if (lineCount >= lineMidpoint)
                   patternIndex1 <= 1;
           end
        end
        else begin
           pixelCount <= pixelCount + 1;
           if (pixelCount >= pixelMidpoint)
               patternIndex0 <= 1;
        end
        dataEnable <= (lineCount >= deLinePorch && lineCount < deLineVisible
                   && pixelCount >= dePixelPorch && pixelCount < dePixelVisible);
    endrule
    rule zzz if (!dataEnable && lineCount == deLinePorch-4);
       zeropixel <= 0;
       pixelcount <= 0;
       pixelcount2 <= 0;
    endrule
    rule zz23 if (dataEnable);
       pixelcount2 <= pixelcount2 + 1;
    endrule

    rule output_data_rule if (!dataEnable);
        rgb888StageReg <= VideoData {de: 0, pixel: unpack(0),
               vsync: pack(lineCount <= deLineWidth), hsync: pack(pixelCount <= dePixelWidth) };
    endrule

    rule testpattern_rule if (testPatternEnabled != 0 && dataEnable);
        rgb888StageReg <= VideoData {de: 1, vsync: 0, hsync: 0, pixel: unpack(patternRegs[{patternIndex1, patternIndex0}]) };
    endrule

    interface Put request;
        method Action put(Bit#(32) v) if (testPatternEnabled == 0 && dataEnable);
           if (v[23:0] == 0 && lineCount < deLinePorch + 100 && pixelCount < dePixelPorch + 100)
               zeropixel <= zeropixel + 1;
           pixelcount <= pixelcount + 1;
           rgb888StageReg <= VideoData {de: 1, vsync: 0, hsync: 0, pixel: unpack(v[23:0])};
        endmethod
    endinterface: request

    interface HdmiInternalRequest control;
        method Action setPatternColor(Bit#(32) v);
            patternRegs[0] <= v[23:0]; 
        endmethod
        method Action setTestPattern(Bit#(1) v);
            shadowTestPatternEnabled <= v;
        endmethod
        method Action setDePixel(Bit#(12) width, Bit#(12) porch, Bit#(12) visible, Bit#(12) last, Bit#(12) mid);
            dePixelWidth <= width;
            dePixelPorch <= porch;
            dePixelVisible <= visible;
            dePixelEnd <= last;
            pixelMidpoint <= mid;
        endmethod
        method Action setDeLine(Bit#(11) width, Bit#(11) porch, Bit#(11) visible, Bit#(11) last, Bit#(11) mid);
            deLineWidth <= width;
            deLinePorch <= porch;
            deLineVisible <= visible;
            deLineEnd <= last;
            lineMidpoint <= mid;
        endmethod
        method Action waitForVsync(Bit#(32) unused);
            waitingForVsync <= True;
        endmethod
    endinterface
   interface Get rgb888;
      method ActionValue#(VideoData#(Rgb888)) get();
	 return rgb888StageReg;
      endmethod
   endinterface
endmodule

module mkHDMI#(Get#(VideoData#(pixelType)) videoInput)(HDMI#(Bit#(pixelsz)))
   provisos (Bits#(VideoData#(pixelType), a__), Bits#(pixelType,pixelsz));
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
   Wire#(VideoData#(pixelType)) video <- mkDWire(unpack(0));
   rule getvideo;
      let v <- videoInput.get();
      video <= v;
   endrule

   method Bit#(1) hdmi_vsync;
      return video.vsync;
   endmethod
   method Bit#(1) hdmi_hsync;
      return video.hsync;
   endmethod
   method Bit#(1) hdmi_de;
      return video.de;
   endmethod
   method Bit#(pixelsz) hdmi_data;
      return pack(video.pixel);
   endmethod
   interface hdmi_clock_if = defaultClock;
   interface deleteme_unused_reset = defaultReset;
endmodule

interface Rgb888ToYyuv;
   interface Put#(VideoData#(Rgb888)) rgb888;
   interface Get#(VideoData#(Yyuv)) yyuv;
endinterface

(* synthesize *)
module mkRgb888ToYyuv(Rgb888ToYyuv);
    Reg#(VideoData#(Rgb888))                        stage0Reg <- mkReg(unpack(0));
    Reg#(VideoData#(Yuv444Intermediates))           stage1Reg <- mkReg(unpack(0));
    Reg#(VideoData#(Vector#(2,Vector#(3,Bit#(16))))) stage2Reg <- mkReg(unpack(0));
    Reg#(VideoData#(Yuv444))                        stage3Reg <- mkReg(unpack(0));
    Reg#(VideoData#(Yyuv))                          stage4Reg <- mkReg(unpack(0));
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

    rule stage4_rule;
        let previous = stage3Reg;
        if (previous.de != 0)
            evenOddPixelReg <= !evenOddPixelReg;
        Yyuv data = Yyuv { uv: evenOddPixelReg ? previous.pixel.u : previous.pixel.v,
                           yy: previous.pixel.y };
        stage4Reg <= VideoData {
            vsync: previous.vsync, hsync: previous.hsync, de: previous.de,
            pixel: data
        };
    endrule

   interface Put rgb888;
      method Action put(VideoData#(Rgb888) v);
	 stage0Reg <= v;
      endmethod
   endinterface
   interface Get yyuv;
      method ActionValue#(VideoData#(Yyuv)) get();
	 return stage4Reg;
      endmethod
   endinterface
endmodule
