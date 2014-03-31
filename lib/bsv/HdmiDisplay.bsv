
// Copyright (c) 2012 Nokia, Inc.
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

import FIFOF::*;
import Clocks::*;
import GetPut::*;
import PCIE::*;
import GetPutWithClocks::*;
import Connectable::*;
import PortalMemory::*;
import Dma::*;
import DmaUtils::*;
import AxiMasterSlave::*;
import HDMI::*;
import XADC::*;
import YUV::*;

interface HdmiControlRequest;
    method Action startFrameBuffer0(Int#(32) base);
endinterface

interface HdmiDisplay;
    interface HdmiControlRequest controlRequest;
    interface HdmiInternalRequest internalRequest;
    interface ObjectReadClient#(64) dmaClient;
    interface HDMI hdmi;
    interface XADC xadc;
endinterface

module mkHdmiDisplay#(Clock processing_system7_1_fclk_clk1,
		      HdmiInternalIndication hdmiInternalIndication)(HdmiDisplay);
    Clock defaultClock <- exposeCurrentClock;
    Reset defaultReset <- exposeCurrentReset;
    Clock hdmi_clock = processing_system7_1_fclk_clk1;
    Reset hdmi_reset <- mkAsyncReset(2, defaultReset, hdmi_clock);
    Reg#(Bool) sendVsyncIndication <- mkReg(False);
    SyncPulseIfc vsyncPulse <- mkSyncHandshake(hdmi_clock, hdmi_reset, defaultClock);
    Reg#(Bit#(1)) bozobit <- mkReg(0, clocked_by hdmi_clock, reset_by hdmi_reset);
    Reg#(Bit#(8)) segmentIndexReg <- mkReg(0);
    Reg#(Bit#(24)) segmentOffsetReg <- mkReg(0);

    Reg#(ObjectPointer) referenceReg <- mkReg(-1);
    Reg#(Bit#(40)) streamRdOff <- mkReg(0);

    HdmiGenerator hdmiGen <- mkHdmiGenerator(defaultClock, defaultReset,
					     vsyncPulse, hdmiInternalIndication, clocked_by hdmi_clock, reset_by hdmi_reset);
   
    DmaReadBuffer#(64, 1) dmaReadBuffer <- mkDmaReadBuffer();
    rule readReq if(referenceReg >= 0);
        streamRdOff <= streamRdOff + 16*8;
        dmaReadBuffer.dmaServer.readReq.put(ObjectRequest {pointer: referenceReg, offset: streamRdOff, burstLen: 16, tag: 0});
    endrule
   Put#(ObjectData#(64)) sink = (interface Put;
      method Action put(ObjectData#(64) dmadata);
         hdmiGen.request.put(dmadata.data);
      endmethod
      endinterface);
    mkConnectionWithClocks(dmaReadBuffer.dmaServer.readData, sink, defaultClock, defaultReset, hdmi_clock, hdmi_reset);

    rule vsyncrule if (vsyncPulse.pulse() && referenceReg >= 0);
       streamRdOff <= 0;
    endrule

    rule bozobit_rule;
        bozobit <= ~bozobit;
    endrule

    interface HdmiControlRequest controlRequest;
	method Action startFrameBuffer0(Int#(32) base);
	    $display("startFrameBuffer %h", base);
            referenceReg <= truncate(pack(base));
	    hdmiGen.control.setTestPattern(0);
	endmethod
    endinterface: controlRequest

    interface ObjectReadClient dmaClient = dmaReadBuffer.dmaClient;
    interface HDMI hdmi = hdmiGen.hdmi;
    interface HdmiInternalRequest internalRequest = hdmiGen.control;
    interface XADC xadc;
        method Bit#(4) gpio;
            return { bozobit, hdmiGen.hdmi.vsync,
                hdmiGen.hdmi.data[8], hdmiGen.hdmi.data[0]};
                //hdmiGen.hdmi.hsync, hdmi_de};
        endmethod
    endinterface: xadc
endmodule
