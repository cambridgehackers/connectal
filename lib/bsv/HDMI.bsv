
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
import GetPut::*;
import SyncBits::*;
import YUV::*;

interface HDMI;
    method Bit#(1) vsync;
    method Bit#(1) hsync;
    method Bit#(1) de;
    method Bit#(16) data;
    interface Clock clock_if;
    interface Reset reset_if;
endinterface

interface HdmiInternalRequest;
    method Action setTestPattern(Bit#(1) v);
    method Action setPatternColor(Bit#(32) v);
    method Action setHsyncWidth(Bit#(12) hsyncWidth);
    method Action setDePixelCountMinMax(Bit#(12) min, Bit#(12) max);
    method Action setVsyncWidth(Bit#(11) vsyncWidth);
    method Action setDeLineCountMinMax(Bit#(11) min, Bit#(11) max);
    method Action setNumberOfLines(Bit#(11) lines);
    method Action setNumberOfPixels(Bit#(12) pixels);
    method Action waitForVsync(Bit#(32) unused);
endinterface
interface HdmiInternalIndication;
    method Action vsync(Bit#(64) v);
endinterface

interface HdmiGenerator;
    interface HdmiInternalRequest control;
    interface HDMI hdmi;
    interface Put#(Bit#(64)) request;
endinterface

module mkHdmiGenerator#(Clock axi_clock, Reset axi_reset,
        SyncPulseIfc vsyncPulse, HdmiInternalIndication indication)(HdmiGenerator);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    // 1920 * 1080
    Reg#(Bit#(12)) hsyncWidth <- mkSyncReg(44, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(12)) dePixelCountMinimum <- mkSyncReg(192, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(12)) dePixelCountMaximum <- mkSyncReg(1920 + 192, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(12)) pixelMidpoint <- mkSyncReg((1920/2) + 192, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(11)) vsyncWidth <- mkSyncReg(5, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(11)) deLineCountMinimum <- mkSyncReg(41, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(11)) deLineCountMaximum <- mkSyncReg(1080+41, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(11)) lineMidpoint <- mkSyncReg((1080/2) + 41, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(11)) numberOfLines <- mkSyncReg(1080 + 45, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(12)) numberOfPixels <- mkSyncReg(1920 + 192 + 44 + 44, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(11)) lineCount <- mkReg(0);
    Reg#(Bit#(12)) pixelCount <- mkReg(0);
    Vector#(4, Reg#(Bit#(24))) patternRegs <- replicateM(mkSyncReg(24'h00FFFFFF, axi_clock, axi_reset, defaultClock));
    Reg#(Bit#(1)) shadowTestPatternEnabled <- mkSyncReg(1, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(1)) testPatternEnabled <- mkReg(1);
    Reg#(Bool) waitingForVsync <- mkSyncReg(False, axi_clock, axi_reset, defaultClock);
    SyncPulseIfc sendVsyncIndication <- mkSyncPulse(defaultClock, defaultReset, axi_clock);
    Reg#(Bit#(24)) pixelData <- mkReg(24'h00ff00ff);

    Reg#(Rgb888Stage) rgb888StageReg <- mkReg(unpack(0));
    Reg#(Yuv444IntermediatesStage) yuv444IntermediatesStageReg <- mkReg(unpack(0));
    Reg#(Yuv444Stage) yuv444StageReg <- mkReg(unpack(0));
    Reg#(Yuv422Stage) yuv422StageReg <- mkReg(unpack(0));
    Reg#(Bool) evenOddPixelReg <- mkReg(False);

   Reg#(Bit#(32)) counter <- mkReg(0, clocked_by axi_clock, reset_by axi_reset);
   Reg#(Bit#(32)) elapsed <- mkReg(0, clocked_by axi_clock, reset_by axi_reset);
   rule axicyclecount;
      counter <= counter + 1;
   endrule
      
    rule vsyncReceived if (sendVsyncIndication.pulse());
       elapsed <= counter;
       indication.vsync(extend(counter - elapsed));
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
        if (lineCount == 0 && pixelCount == 0)
            begin
            vsyncPulse.send();
            if (waitingForVsync) begin
	       sendVsyncIndication.send();
	    end
            testPatternEnabled <= shadowTestPatternEnabled;
            end
        if (pixelCount == numberOfPixels-1)
           begin
           pixelCount <= 0; 
           if (lineCount == numberOfLines-1)
               lineCount <= 0;
           else
               lineCount <= lineCount+1;
           end
        else
            pixelCount <= pixelCount + 1;
    endrule

    rule output_data_rule;
        let hsync = (pixelCount < hsyncWidth) ? 1 : 0;
        let vsync = (lineCount < vsyncWidth) ? 1 : 0;
        let isActiveLine = (lineCount >= deLineCountMinimum && lineCount < deLineCountMaximum);
        let dataEnable = (pixelCount >= dePixelCountMinimum && pixelCount < dePixelCountMaximum && isActiveLine);
        Rgb888 pixel = unpack(pixelData);
        rgb888StageReg <= Rgb888Stage{de: pack(dataEnable),
            vsync: vsync, hsync: hsync, pixel: pixel };
    endrule

    rule test_rule if (testPatternEnabled != 0);
        pixelData <= patternRegs[{pack(lineCount >= lineMidpoint), pack(pixelCount >= pixelMidpoint)}];
    endrule

    rule yuv444int_rule;
        let previous = rgb888StageReg;
        let pixel = previous.pixel;
        yuv444IntermediatesStageReg <= Yuv444IntermediatesStage {
            vsync: previous.vsync, hsync: previous.hsync, de: previous.de,
            data: (previous.de != 0) ? rgbToYuvIntermediates(pixel) : unpack(0)
        };
    endrule

    rule yuv444_rule;
        let previous = yuv444IntermediatesStageReg;
        yuv444StageReg <= Yuv444Stage {
            vsync: previous.vsync, hsync: previous.hsync, de: previous.de,
            data: (previous.de != 0) ? yuvIntermediatesToYuv444(previous.data) : unpack(0)
        };
    endrule

    rule yuv422_rule;
        let previous = yuv444StageReg;
        if (previous.de != 0)
            evenOddPixelReg <= !evenOddPixelReg;
        Bit#(16) data = { evenOddPixelReg ? previous.data.u : previous.data.v,
                          previous.data.y };
        yuv422StageReg <= Yuv422Stage {
            vsync: previous.vsync, hsync: previous.hsync, de: previous.de,
            data: data
        };
    endrule

    interface Put request;
        method Action put(Bit#(64) v) if (testPatternEnabled == 0);
	    pixelData <= v[23:0];
        endmethod
    endinterface: request

    interface HdmiInternalRequest control;
        method Action setPatternColor(Bit#(32) v);
            patternRegs[0] <= v[23:0]; 
        endmethod
        method Action setTestPattern(Bit#(1) v);
            shadowTestPatternEnabled <= v;
        endmethod
        method Action setHsyncWidth(Bit#(12) width);
            hsyncWidth <= width;
        endmethod
        method Action setDePixelCountMinMax(Bit#(12) min, Bit#(12) max);
            dePixelCountMinimum <= min;
            dePixelCountMaximum <= max;
            pixelMidpoint <= (min + max) / 2;
        endmethod
        method Action setVsyncWidth(Bit#(11) width);
            vsyncWidth <= width;
        endmethod
        method Action setDeLineCountMinMax(Bit#(11) min, Bit#(11) max);
            deLineCountMinimum <= min;
            deLineCountMaximum <= max;
            lineMidpoint <= (min + max) / 2;
        endmethod
        method Action setNumberOfLines(Bit#(11) lines);
            numberOfLines <= lines;
        endmethod
        method Action setNumberOfPixels(Bit#(12) pixels);
            numberOfPixels <= pixels;
        endmethod
        method Action waitForVsync(Bit#(32) unused);
            waitingForVsync <= True;
        endmethod
    endinterface
    interface HDMI hdmi;
        method Bit#(1) vsync;
            return yuv422StageReg.vsync;
        endmethod
        method Bit#(1) hsync;
            return yuv422StageReg.hsync;
        endmethod
        method Bit#(1) de;
            return yuv422StageReg.de;
        endmethod
        method Bit#(16) data;
            return yuv422StageReg.data;
        endmethod
        interface clock_if = defaultClock;
        interface reset_if = defaultReset;
    endinterface
endmodule
