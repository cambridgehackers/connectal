
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

import AxiMasterSlave::*;
import AxiClientServer::*;
import HDMI::*;
import XADC::*;
import FrameBufferBram::*;
import YUV::*;

interface HdmiControlRequest;
    method Action startFrameBuffer0(Bit#(32) base);
    method Action hdmiLinesPixels(Bit#(32) value);
    method Action hdmiStrideBytes(Bit#(32) strideBytes);
    method Action beginTranslationTable(Bit#(8) index);
    method Action addTranslationEntry(Bit#(20) address, Bit#(12) length); // shift address and length left 12 bits
endinterface

interface HdmiDisplayRequest;
    interface HdmiControlRequest coreRequest;
    interface HdmiInternalRequest coRequest;
    interface DMARequest dmaRequest;
    interface Axi3Client#(32,32,4,6) m_axi;
    interface HDMI hdmi;
    interface XADC xadc;
endinterface

interface HdmiControlIndication;
endinterface

interface HdmiDisplayIndication;
    interface HdmiControlIndication coreIndication;
    interface HdmiInternalIndication coIndication;
    interface DMAIndication dmaIndication;
endinterface

module mkHdmiDisplayRequest#(Clock processing_system7_1_fclk_clk1, HdmiDisplayIndication indication)(HdmiDisplayRequest);
    let busWidthBytes=8;

    Clock defaultClock <- exposeCurrentClock;
    Reset defaultReset <- exposeCurrentReset;
    Clock hdmi_clock = processing_system7_1_fclk_clk1;
    Reset hdmi_reset <- mkAsyncReset(2, defaultReset, hdmi_clock);
    Reg#(Bool) sendVsyncIndication <- mkReg(False);
    Reg#(Bit#(11)) linesReg <- mkReg(1080);
    Reg#(Bit#(12)) pixelsReg <- mkReg(1920);
    Reg#(Bit#(14)) strideBytesReg <- mkReg(1920*4);
    SyncPulseIfc vsyncPulse <- mkSyncHandshake(hdmi_clock, hdmi_reset, defaultClock);
    SyncPulseIfc hsyncPulse <- mkSyncHandshake(hdmi_clock, hdmi_reset, defaultClock);
    Reg#(Bit#(1)) bozobit <- mkReg(0, clocked_by hdmi_clock, reset_by hdmi_reset);
    Reg#(Bit#(8)) segmentIndexReg <- mkReg(0);
    Reg#(Bit#(24)) segmentOffsetReg <- mkReg(0);
    Reg#(Bool) frameBufferEnabled <- mkReg(False);
    FrameBufferBram frameBuffer <- mkFrameBufferBram(hdmi_clock, hdmi_reset);
    HdmiGenerator hdmiGen <- mkHdmiGenerator(defaultClock, defaultReset,
        frameBuffer.buffer, vsyncPulse, hsyncPulse, indication.coIndication, clocked_by hdmi_clock, reset_by hdmi_reset);

    (* descending_urgency = "vsync, hsync" *)
    rule vsync if (vsyncPulse.pulse());
        $display("vsync pulse received %h", frameBufferEnabled);
        if (frameBufferEnabled)
        begin
            $display("frame started");
            frameBuffer.startFrame();
        end
    endrule
    rule hsync if (hsyncPulse.pulse());
        frameBuffer.startLine();
    endrule

    rule bozobit_rule;
        bozobit <= ~bozobit;
    endrule

    interface HdmiControlRequest coreRequest;
	method Action hdmiLinesPixels(Bit#(32) value);
	    linesReg <= value[10:0];
	    pixelsReg <= value[27:16];
            hdmiGen.control.setNumberOfLines(linesReg);
            hdmiGen.control.setNumberOfPixels(pixelsReg);
	endmethod
	method Action hdmiStrideBytes(Bit#(32) value);
	    strideBytesReg <= value[13:0];
	endmethod
	method Action startFrameBuffer0(Bit#(32) base);
	    $display("startFrameBuffer %h", base);
	    frameBufferEnabled <= True;
	    FrameBufferConfig fbc;
	    fbc.base = base;
	    fbc.pixels = pixelsReg;
	    fbc.lines = linesReg;
	    fbc.stridebytes = strideBytesReg;
	    frameBuffer.configure(fbc);
	    $display("startFrameBuffer lines %d pixels %d bytesperpixel %d stridebytes %d",
		     linesReg, pixelsReg, bytesperpixel, strideBytesReg);
	    hdmiGen.control.setTestPattern(0);
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
    interface HdmiInternalRequest coRequest = hdmiGen.control;
    interface XADC xadc;
        method Bit#(4) gpio;
            return { bozobit, hdmiGen.hdmi.hdmi_vsync,
                hdmiGen.hdmi.hdmi_data[8], hdmiGen.hdmi.hdmi_data[0]};
                //hdmiGen.hdmi.hdmi_hsync, hdmi_de};
        endmethod
    endinterface: xadc
endmodule
