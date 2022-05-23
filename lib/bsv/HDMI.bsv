
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

`include "ConnectalProjectConfig.bsv"
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

interface HdmiGeneratorRequest;
    method Action setTestPattern(Bit#(1) v);
    method Action setPatternColor(Bit#(32) v);
    method Action setDePixel(Bit#(12) frontPorch, Bit#(12) syncWidth, Bit#(12) visible, Bit#(12) last, Bit#(12) mid);
    method Action setDeLine(Bit#(11) frontPorch, Bit#(11) syncWidth, Bit#(11) visible, Bit#(11) last, Bit#(11) mid);
    method Action waitForVsync(Bit#(32) unused);
endinterface
interface HdmiGeneratorIndication;
    method Action vsync(Bit#(64) v, Bit#(32) vs);
endinterface

interface HdmiGenerator#(type pixelType);
    interface HdmiGeneratorRequest request;
    interface Get#(VideoData#(pixelType)) rgb888;
    interface Put#(Bit#(32)) pdata;
endinterface

module mkHdmiGenerator#(Clock axi_clock, Reset axi_reset,
   SyncPulseIfc startDMA, HdmiGeneratorIndication indication)(HdmiGenerator#(Rgb888));
    let verbose = True;
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    // 1920 * 1080
    // horiz: frontPorch:87, sync: 44, backPorch:148, pixel:1920
    // vert: frontPorch:3, sync:5, backPorch:36, lines:1080
`define hFront   87
`define hSync    44
`define hBack   148
`define hPixel 1920
`define vFront    3
`define vSync     5
`define vBack    36
`define vLines 1080
//`define hFront   88
//`define hSync    44
//`define hBack   280
//`define hPixel 1920
//`define vFront    4
//`define vSync     5
//`define vBack    45
//`define vLines 1080
    Reg#(Bit#(12)) dePixelStartSync <- mkSyncReg(              `hFront, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(12)) dePixelEndSync <- mkSyncReg(           `hSync + `hFront, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(12)) dePixelStartVisible <- mkSyncReg(`hBack + `hSync + `hFront, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(12)) dePixelEnd <- mkSyncReg(  `hPixel + `hBack + `hSync + `hFront, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(12)) dePixelMid <- mkSyncReg((`hPixel/2) + `hBack + `hSync, axi_clock, axi_reset, defaultClock);

    Reg#(Bit#(11)) deLineStartSync <- mkSyncReg(              `vFront, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(11)) deLineEndSync <- mkSyncReg(            `vSync + `vFront, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(11)) deLineStartVisible <- mkSyncReg(  `vBack + `vSync + `vFront, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(11)) deLineEnd <- mkSyncReg(    `vLines + `vBack + `vSync + `vFront, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(11)) deLineMid <- mkSyncReg((`vLines/2) + `vBack + `vSync, axi_clock, axi_reset, defaultClock);

    Vector#(4, Reg#(Bit#(24))) patternRegs <- replicateM(mkSyncReg(24'h00FFFFFF, axi_clock, axi_reset, defaultClock));
    Reg#(Bit#(1)) shadowTestPatternEnabled <- mkSyncReg(1, axi_clock, axi_reset, defaultClock);
    Reg#(Bool) waitingForVsync <- mkSyncReg(False, axi_clock, axi_reset, defaultClock);
    SyncPulseIfc sendVsyncIndication <- mkSyncHandshake(defaultClock, defaultReset, axi_clock);

    Reg#(Bit#(11)) lineCount <- mkReg(0);
    Reg#(Bit#(12)) pixelCount <- mkReg(0);
    Reg#(Bit#(1)) patternIndex0 <- mkReg(0);
    Reg#(Bit#(1)) patternIndex1 <- mkReg(0);
    Reg#(Bit#(1)) testPatternEnabled <- mkReg(1);
    Reg#(Bool) dataEnable <- mkReg(False);
    Reg#(Bool) lineVisible <- mkReg(False);
    Reg#(Bit#(1)) vsync <- mkReg(0);
    Reg#(Bit#(1)) hsync <- mkReg(0);
    Reg#(Bit#(32)) vsyncCounter <- mkReg(0);

    Reg#(VideoData#(Rgb888)) rgb888StageReg <- mkReg(unpack(0));
    Reg#(Bool) evenOddPixelReg <- mkReg(False);

    Reg#(Bit#(32)) underflowCount <- mkReg(0);
    Reg#(Bit#(32)) underflowCountAxi <- mkSyncReg(0, defaultClock, defaultReset, axi_clock);
    Reg#(Bit#(32)) counter <- mkReg(0, clocked_by axi_clock, reset_by axi_reset);
    Reg#(Bit#(32)) elapsed <- mkReg(0, clocked_by axi_clock, reset_by axi_reset);
    Reg#(Bit#(32)) elapsedVsync <- mkReg(0, clocked_by axi_clock, reset_by axi_reset);
    SyncBitIfc#(Bit#(32)) vsyncCounters <- mkSyncBits(0, defaultClock, defaultReset, axi_clock, axi_reset);
    Wire#(Bool) gotDataWire <- mkDWire(False);

    rule vsyncaxi;
       vsyncCounters.send(vsyncCounter);
    endrule

    rule axicyclecount;
       counter <= counter + 1;
    endrule
      
    rule vsyncReceived if (sendVsyncIndication.pulse());
       $display("HDMI: sending vsync");
       elapsed <= counter;
       elapsedVsync <= vsyncCounters.read();
       indication.vsync(extend(elapsed - counter), vsyncCounter - vsyncCounter);
       waitingForVsync <= False;
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
        if (pixelCount == dePixelEnd) begin
           if (testPatternEnabled == 0 && verbose)
               $display("HDMI: endofline %d", lineCount);
           pixelCount <= 0; 
           dataEnable <= False;
           patternIndex0 <= 0;
           if (lineCount == deLineEnd) begin
               lineCount <= 0;
               patternIndex1 <= 0;
               lineVisible <= False;
               if (verbose)
                   $display("HDMI: lineVisible off");
               testPatternEnabled <= shadowTestPatternEnabled;
               $display("HDMI: lineend %d", waitingForVsync);
               if (waitingForVsync)
	          sendVsyncIndication.send();
           end
           else begin
               if (lineCount == deLineStartVisible) begin
                   lineVisible <= True;
                   if (verbose)
                       $display("HDMI: lineVisible on");
               end
               lineCount <= lineCount+1;
               if (lineCount >= deLineMid)
                   patternIndex1 <= 1;
           end
        end
        else begin
           if (lineCount == deLineStartSync) begin
              vsync <= 1;
              if (pixelCount == 0 && testPatternEnabled == 0) begin
                  vsyncCounter <= vsyncCounter+1;
                  startDMA.send();
                  $display("HDMI:vsync %d", lineCount);
              end
           end
           else if (lineCount == deLineEndSync)
              vsync <= 0;
           if (pixelCount == dePixelStartSync)
              hsync <= 1;
           else if (pixelCount == dePixelEndSync)
              hsync <= 0;
           if (pixelCount == dePixelStartVisible)
               dataEnable <= lineVisible;
           pixelCount <= pixelCount + 1;
           if (pixelCount == dePixelMid)
               patternIndex0 <= 1;
        end
    endrule

    rule output_data_rule if (!dataEnable);
        rgb888StageReg <= VideoData {de: 0, pixel: unpack(0), vsync: vsync, hsync: hsync };
    endrule

    rule testpattern_rule if (testPatternEnabled != 0 && dataEnable);
        rgb888StageReg <= VideoData {de: 1, vsync: 0, hsync: 0, pixel: unpack(patternRegs[{patternIndex1, patternIndex0}])};
    endrule

    rule gdr if (testPatternEnabled == 0 && dataEnable && !gotDataWire);
        $display("HDMI::nodata [%d:%d]", lineCount, pixelCount);
    endrule

    interface Put pdata;
        method Action put(Bit#(32) v) if (testPatternEnabled == 0 && dataEnable);
           rgb888StageReg <= VideoData {de: 1, vsync: 0, hsync: 0, pixel: unpack(v[23:0])};
           gotDataWire <= True;
           //if (verbose)
               //$display("HDMI::pdata         [%d:%d] = %x", lineCount, pixelCount, v);
        endmethod
    endinterface

    interface HdmiGeneratorRequest request;
        method Action setPatternColor(Bit#(32) v);
            patternRegs[0] <= v[23:0]; 
        endmethod
        method Action setTestPattern(Bit#(1) v);
            shadowTestPatternEnabled <= v;
        endmethod
        method Action setDePixel(Bit#(12) frontPorch, Bit#(12) syncWidth, Bit#(12) visible, Bit#(12) last, Bit#(12) mid);
            dePixelStartSync <= frontPorch;
            dePixelEndSync <= syncWidth;
            dePixelStartVisible <= visible;
            dePixelEnd <= last;
            dePixelMid <= mid;
        endmethod
        method Action setDeLine(Bit#(11) frontPorch, Bit#(11) syncWidth, Bit#(11) visible, Bit#(11) last, Bit#(11) mid);
            deLineStartSync <= frontPorch;
            deLineEndSync <= syncWidth;
            deLineStartVisible <= visible;
            deLineEnd <= last;
            deLineMid <= mid;
        endmethod
        method Action waitForVsync(Bit#(32) unused);
            waitingForVsync <= True;
            $display("HDMI: waitForVsync set");
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
