
// Copyright (c) 2012 Nokia, Inc.

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

import FIFOF::*;
import BRAMFIFO::*;
import Clocks::*;
import GetPut::*;
import Connectable::*;
import PortalMemory::*;
import AxiDMA::*;

import AxiMasterSlave::*;
import AxiClientServer::*;
import HDMI::*;
import FrameBufferBram::*;
import YUV::*;

interface HdmiControlRequest;
    method Action setPatternReg(Bit#(32) yuv422);
    method Action startFrameBuffer0(Bit#(32) base);
    method Action startFrameBuffer1(Bit#(32) base);

    method Action waitForVsync(Bit#(32) unused);

    method Action hdmiLinesPixels(Bit#(32) value);
    method Action hdmiBlankLinesPixels(Bit#(32) value);
    method Action hdmiStrideBytes(Bit#(32) strideBytes);
    method Action hdmiLineCountMinMax(Bit#(32) value);
    method Action hdmiPixelCountMinMax(Bit#(32) value);
    method Action hdmiSyncWidths(Bit#(32) value);

    method Action beginTranslationTable(Bit#(8) index);
    method Action addTranslationEntry(Bit#(20) address, Bit#(12) length); // shift address and length left 12 bits
endinterface

interface HdmiDisplayRequest;
    interface HdmiControlRequest coreRequest;
    interface DMARequest dmaRequest;
    interface Axi3Client#(32,32,4,6) m_axi;
    interface HDMI hdmi;
endinterface

interface HdmiControlIndication;
    method Action vsync(Bit#(64) v);
endinterface

interface HdmiDisplayIndication;
    interface HdmiControlIndication coreIndication;
    interface DMAIndication dmaIndication;
endinterface

function Put#(item_t) syncFifoToPut( SyncFIFOIfc#(item_t) f);
    return (
        interface Put;
            method Action put (item_t item);
                f.enq(item);
            endmethod
        endinterface
    );
endfunction

module mkHdmiDisplayRequest#(Clock processing_system7_1_fclk_clk1, HdmiDisplayIndication indication)(HdmiDisplayRequest);
    Clock hdmi_clock = processing_system7_1_fclk_clk1;
    let busWidthBytes=8;

    Reg#(Bit#(32)) vsyncPulseCountReg <- mkReg(0);
    Reg#(Bit#(32)) frameCountReg <- mkReg(0);

    Reg#(Bool) waitingForVsync <- mkReg(False);
    Reg#(Bool) sendVsyncIndication <- mkReg(False);

    Clock clock <- exposeCurrentClock;
    Reset reset <- exposeCurrentReset;

    Reset hdmi_reset <- mkAsyncReset(2, reset, hdmi_clock);

    Reg#(Bit#(11)) linesReg <- mkReg(1080);
    Reg#(Bit#(12)) pixelsReg <- mkReg(1920);
    Reg#(Bit#(14)) strideBytesReg <- mkReg(1920*4);

    SyncPulseIfc vsyncPulse <- mkSyncHandshake(hdmi_clock, hdmi_reset, clock);
    SyncPulseIfc hsyncPulse <- mkSyncHandshake(hdmi_clock, hdmi_reset, clock);
    SyncFIFOIfc#(HdmiCommand) commandFifo <- mkSyncFIFOFromCC(1, hdmi_clock);

    Reg#(Bit#(8)) segmentIndexReg <- mkReg(0);
    Reg#(Bit#(24)) segmentOffsetReg <- mkReg(0);

    Reg#(Bool) frameBufferEnabled <- mkReg(False);
    FrameBufferBram frameBuffer <- mkFrameBufferBram(hdmi_clock, hdmi_reset);

    HdmiGenerator hdmiGen <- mkHdmiGenerator(clocked_by hdmi_clock, reset_by hdmi_reset,
                                             commandFifo, frameBuffer.buffer,
					     vsyncPulse, hsyncPulse);

    (* descending_urgency = "vsync, hsync" *)
    rule vsync if (vsyncPulse.pulse());
        $display("vsync pulse received %h", frameBufferEnabled);
        vsyncPulseCountReg <= vsyncPulseCountReg + 1;
        if (waitingForVsync)
        begin
            waitingForVsync <= False;
            sendVsyncIndication <= True;
        end
        if (frameBufferEnabled)
        begin
            $display("frame started");
            frameCountReg <= frameCountReg + 1;
            frameBuffer.startFrame();
        end
    endrule
    rule hsync if (hsyncPulse.pulse());
        frameBuffer.startLine();
    endrule

    rule vsyncReceived if (sendVsyncIndication);
        sendVsyncIndication <= False;
        Bit#(64) v = 0;
        v[31:0] = vsyncPulseCountReg;
        v[47:32] = extend(pixelsReg);
        v[63:48] = extend(linesReg);
        indication.coreIndication.vsync(v);
    endrule

    interface HdmiControlRequest coreRequest;
	method Action setPatternReg(Bit#(32) yuv422);
	    commandFifo.enq(tagged PatternColor {yuv422: yuv422});
	endmethod
	method Action hdmiLinesPixels(Bit#(32) value);
	    linesReg <= value[10:0];
	    pixelsReg <= value[27:16];
	    commandFifo.enq(tagged LinesPixels {value: value});
	endmethod
	method Action hdmiStrideBytes(Bit#(32) value);
	    strideBytesReg <= value[13:0];
	endmethod
	method Action hdmiBlankLinesPixels(Bit#(32) value);
	    commandFifo.enq(tagged BlankLinesPixels {value: value});
	endmethod
	method Action hdmiLineCountMinMax(Bit#(32) value);
	    commandFifo.enq(tagged LineCountMinMax {value: value});
	endmethod
	method Action hdmiPixelCountMinMax(Bit#(32) value);
	    commandFifo.enq(tagged PixelCountMinMax {value: value});
	endmethod
	method Action hdmiSyncWidths(Bit#(32) value);
	    commandFifo.enq(tagged SyncWidths {value: value});
	endmethod

	method Action startFrameBuffer0(Bit#(32) base);
	    $display("startFrameBuffer %h", base);
	    frameBufferEnabled <= True;
	    FrameBufferConfig fbc;
	    fbc.base = base;
	    fbc.pixels = pixelsReg;
	    fbc.lines = linesReg;
	    Bit#(14) stridebytes = strideBytesReg;
	    $display("startFrameBuffer lines %d pixels %d bytesperpixel %d stridebytes %d",
		     linesReg, pixelsReg, bytesperpixel, stridebytes);
	    fbc.stridebytes = stridebytes;
	    frameBuffer.configure(fbc);
	    commandFifo.enq(tagged TestPattern {enabled: False});
	    waitingForVsync <= True;
	endmethod

	method Action startFrameBuffer1(Bit#(32) base);
	endmethod

	method Action waitForVsync(Bit#(32) unused);
	    waitingForVsync <= True;
	endmethod

	method Action beginTranslationTable(Bit#(8) index);
	    segmentIndexReg <= index;
	    segmentOffsetReg <= 0;
	endmethod
	method Action addTranslationEntry(Bit#(20) address, Bit#(12) length);
	    frameBuffer.setSgEntry(segmentIndexReg, segmentOffsetReg, address, extend(length));
	    segmentIndexReg <= segmentIndexReg + 1;
	    segmentOffsetReg <= segmentOffsetReg + {length,12'd0};
	endmethod
    endinterface: coreRequest

    interface Axi3Client m_axi = frameBuffer.axi;
    interface HDMI hdmi = hdmiGen.hdmi;
endmodule
