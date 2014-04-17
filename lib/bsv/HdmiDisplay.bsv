
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

import FIFO::*;
import FIFOF::*;
import Vector::*;
import Clocks::*;
import GetPut::*;
import PCIE::*;
import GetPutWithClocks::*;
import Connectable::*;
import PortalMemory::*;
import Dma::*;
import DmaUtils::*;
import AxiMasterSlave::*;
import MemreadEngine::*;
import HDMI::*;
import XADC::*;
import YUV::*;

interface HdmiDisplayRequest;
   method Action startFrameBuffer0(Int#(32) base);
   method Action getTransferStats();
   method Action setTraceTransfers(Bool trace);
endinterface
interface HdmiDisplayIndication;
   method Action transferStarted(Bit#(32) count);
   method Action transferFinished(Bit#(32) count);
   method Action transferStats(Bit#(32) count, Bit#(32) transferCycles, Bit#(64) sumOfCycles);
endinterface

interface HdmiDisplay;
    interface HdmiDisplayRequest displayRequest;
    interface HdmiInternalRequest internalRequest;
    interface ObjectReadClient#(64) dmaClient;
    interface HDMI hdmi;
    interface XADC xadc;
endinterface

module mkHdmiDisplay#(Clock hdmi_clock,
		      HdmiDisplayIndication hdmiDisplayIndication,
		      HdmiInternalIndication hdmiInternalIndication)(HdmiDisplay);
    Clock defaultClock <- exposeCurrentClock;
    Reset defaultReset <- exposeCurrentReset;
    Reset hdmi_reset <- mkAsyncReset(2, defaultReset, hdmi_clock);
    Reg#(Bool) sendVsyncIndication <- mkReg(False);
    SyncPulseIfc vsyncPulse <- mkSyncHandshake(hdmi_clock, hdmi_reset, defaultClock);
    Reg#(Bit#(1)) bozobit <- mkReg(0, clocked_by hdmi_clock, reset_by hdmi_reset);

    Reg#(Maybe#(Bit#(32))) referenceReg <- mkReg(tagged Invalid);
    FIFOF#(Bit#(64))   mrFifo  <- mkSizedFIFOF(32);
    MemreadEngine#(64) memreadEngine <- mkMemreadEngine(8, mrFifo);

    HdmiGenerator hdmiGen <- mkHdmiGenerator(defaultClock, defaultReset,
					     vsyncPulse, hdmiInternalIndication, clocked_by hdmi_clock, reset_by hdmi_reset);
   
   SyncFIFOIfc#(Bit#(64)) synchronizer <- mkSyncFIFO(32, defaultClock, defaultReset, hdmi_clock);
   rule doGet;
      let v = mrFifo.first();
      mrFifo.deq();
      synchronizer.enq(v);
   endrule
   Reg#(Bit#(1)) evenOdd <- mkReg(0, clocked_by hdmi_clock, reset_by hdmi_reset);
   Reg#(Vector#(2,Bit#(32))) doublePixelReg <- mkReg(unpack(0), clocked_by hdmi_clock, reset_by hdmi_reset);
   rule doPut;
      Vector#(2,Bit#(32)) doublePixel = doublePixelReg;
      let pixel = doublePixel[evenOdd];
      if (evenOdd == 0) begin
	 doublePixel = unpack(synchronizer.first);
	 synchronizer.deq;
	 pixel = doublePixel[0];
      end
      doublePixelReg <= doublePixel;
      evenOdd <= evenOdd + 1;
      hdmiGen.request.put(pixel);
   endrule      

   FIFOF#(Bool) vsyncFifo <- mkFIFOF();
   rule vsyncrule if (vsyncPulse.pulse());
      if (vsyncFifo.notFull())
	 vsyncFifo.enq(True);
   endrule
   Reg#(Bit#(32)) transferCount <- mkReg(0);
   Reg#(Bit#(32)) transferCycles <- mkReg(0);
   Reg#(Bit#(48)) transferSumOfCycles<- mkReg(0);

   Reg#(Bool) traceTransfers <- mkReg(False);
   rule notransfer if (referenceReg matches tagged Invalid);
      vsyncFifo.deq();
   endrule
   rule startTransfer if (referenceReg matches tagged Valid .reference);
      memreadEngine.start(reference, 0, (1080*1920)*4, 64);
      if (traceTransfers)
	 hdmiDisplayIndication.transferStarted(transferCount);
      transferCycles <= 0;
      vsyncFifo.deq();
   endrule
   rule countCycles;
      transferCycles <= transferCycles + 1;
   endrule
   rule finishTransferRule;
      let b <- memreadEngine.finish();
      transferCount <= transferCount + 1;
      transferSumOfCycles <= transferSumOfCycles + extend(transferCycles);
      if (traceTransfers)
	 hdmiDisplayIndication.transferFinished(transferCount);
   endrule

    rule bozobit_rule;
        bozobit <= ~bozobit;
    endrule

    interface HdmiDisplayRequest displayRequest;
	method Action startFrameBuffer0(Int#(32) base);
	    $display("startFrameBuffer %h", base);
            referenceReg <= tagged Valid truncate(pack(base));
	    hdmiGen.control.setTestPattern(0);
	endmethod
       method Action getTransferStats();
          hdmiDisplayIndication.transferStats(transferCount, transferCycles, extend(transferSumOfCycles));
       endmethod
       method Action setTraceTransfers(Bool trace);
	  traceTransfers <= trace;
       endmethod
    endinterface: displayRequest

    interface ObjectReadClient dmaClient = memreadEngine.dmaClient;
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
