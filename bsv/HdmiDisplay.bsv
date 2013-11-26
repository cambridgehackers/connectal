
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
import AxiSDMA::*;
import BsimSDMA::*;
import PortalSMemory::*;

import AxiMasterSlave::*;
import AxiClientServer::*;
import HDMI::*;
import XADC::*;
import FrameBufferBram::*;
import YUV::*;

interface HdmiControlRequest;
    method Action startFrameBuffer0(Int#(32) base);
    method Action hdmiLinesPixels(Bit#(32) value);
endinterface

interface HdmiControlIndication;
endinterface

interface HdmiDisplayRequest;
    interface HdmiControlRequest coreRequest;
    interface HdmiInternalRequest coRequest;
    interface DMARequest dmaRequest;
    //old interface Axi3Client#(32,32,4,6) m_axi;
    interface Axi3Client#(40,64,8,12) m_axi;
    interface HDMI hdmi;
    interface XADC xadc;
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
    SyncPulseIfc vsyncPulse <- mkSyncHandshake(hdmi_clock, hdmi_reset, defaultClock);
    Reg#(Bit#(1)) bozobit <- mkReg(0, clocked_by hdmi_clock, reset_by hdmi_reset);
    Reg#(Bit#(8)) segmentIndexReg <- mkReg(0);
    Reg#(Bit#(24)) segmentOffsetReg <- mkReg(0);
`ifdef BSIM
    BsimDMA    dma <- mkBsimDMA(indication.dmaIndication);
`else
    AxiDMA     dma <- mkAxiDMA(indication.dmaIndication);
`endif
    ReadChan dma_stream_read_chan = dma.read.readChannels[0];
    Reg#(Int#(32)) referenceReg <- mkReg(-1);
    Reg#(Bit#(32)) streamRdCnt <- mkReg(0);

    HdmiGenerator hdmiGen <- mkHdmiGenerator(defaultClock, defaultReset,
        vsyncPulse, indication.coIndication, clocked_by hdmi_clock, reset_by hdmi_reset);
   
    rule readReq if(referenceReg != 0 && False);
        streamRdCnt <= streamRdCnt-16;
        dma_stream_read_chan.readReq.put(?);
    endrule
    rule consume;
        let v <- dma_stream_read_chan.readData.get;
        hdmiGen.putData(v[31:0]);
        //hdmiGen.putData(v[63:32]);
    endrule

    //(* descending_urgency = "vsyncrule, hsyncrule" *)
    rule vsyncrule if (vsyncPulse.pulse() && referenceReg != 0 && False);
        $display("frame started");
        dma.request.configReadChan(0, pack(referenceReg), 16);
    endrule

    rule bozobit_rule;
        bozobit <= ~bozobit;
    endrule

    interface HdmiControlRequest coreRequest;
	method Action startFrameBuffer0(Int#(32) base);
	    $display("startFrameBuffer %h", base);
            referenceReg <= base;
	    hdmiGen.control.setTestPattern(0);
	endmethod
    endinterface: coreRequest

`ifndef BSIM
    interface Axi3Client m_axi = dma.m_axi;
`endif
    interface DMARequest dmaRequest = dma.request;
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
