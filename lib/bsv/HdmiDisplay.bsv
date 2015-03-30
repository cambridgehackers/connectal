
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

import BRAMFIFO::*;
import Vector::*;
import Clocks::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;
import MemTypes::*;
import MemreadEngine::*;
import HDMI::*;
import XADC::*;
import YUV::*;
import BlueScope::*;

interface HdmiDisplayRequest;
   method Action startFrameBuffer(Int#(32) base, UInt#(32) byteCount);
   method Action stopFrameBuffer();
   method Action getTransferStats();
   method Action setTraceTransfers(Bit#(1) trace);
endinterface
interface HdmiDisplayIndication;
   method Action transferStarted(Bit#(32) count);
   method Action transferFinished(Bit#(32) count);
   method Action transferStats(Bit#(32) count, Bit#(32) transferCycles, Bit#(64) sumOfCycles);
endinterface

interface HdmiDisplay;
`ifdef HDMI_BLUESCOPE
   interface BlueScopeRequest  bluescopeRequest;
   interface MemWriteClient#(64) bluescopeWriteClient;
`endif
    interface HdmiDisplayRequest displayRequest;
    interface HdmiGeneratorRequest internalRequest;
    interface Vector#(1, MemReadClient#(64)) dmaClient;
    interface HDMI#(Bit#(HdmiBits)) hdmi;
    interface XADC xadc;
endinterface

module mkHdmiDisplay#(Clock hdmi_clock,
		      HdmiDisplayIndication hdmiDisplayIndication,
		      HdmiGeneratorIndication hdmiGeneratorIndication
`ifdef HDMI_BLUESCOPE
		      , BlueScopeIndication bluescopeIndication
`endif
                      )(HdmiDisplay);
   Clock defaultClock <- exposeCurrentClock;
   Reset defaultReset <- exposeCurrentReset;
   Reset hdmi_reset <- mkAsyncReset(2, defaultReset, hdmi_clock);
   MakeResetIfc fifo_reset <- mkReset(2, True, defaultClock);
   Reset fifo_reset_hdmi <- mkAsyncReset(2, fifo_reset.new_rst, hdmi_clock);

   Reg#(UInt#(24)) byteCountReg <- mkReg(1080*1920);

   Reg#(Bool) sendVsyncIndication <- mkReg(False);
   SyncPulseIfc startDMA <- mkSyncHandshake(hdmi_clock, hdmi_reset, defaultClock);
   Reg#(Bit#(1)) bozobit <- mkReg(0, clocked_by hdmi_clock, reset_by hdmi_reset);

   Reg#(Maybe#(Bit#(32))) referenceReg <- mkReg(tagged Invalid);
   MemreadEngine#(64,16,1) memreadEngine <- mkMemreadEngine;

   HdmiGenerator#(Rgb888) hdmiGen <- mkHdmiGenerator(defaultClock, defaultReset,
			startDMA, hdmiGeneratorIndication, clocked_by hdmi_clock, reset_by hdmi_reset);
`ifndef ZC706
   Rgb888ToYyuv converter <- mkRgb888ToYyuv(clocked_by hdmi_clock, reset_by fifo_reset_hdmi);
   mkConnection(hdmiGen.rgb888, converter.rgb888);
   HDMI#(Bit#(HdmiBits)) hdmisignals <- mkHDMI(converter.yyuv, clocked_by hdmi_clock, reset_by hdmi_reset);
`else
   HDMI#(Bit#(HdmiBits)) hdmisignals <- mkHDMI(hdmiGen.rgb888, clocked_by hdmi_clock, reset_by hdmi_reset);
`endif   
`ifdef HDMI_BLUESCOPE
   let bluescope <- mkSyncBlueScope(65536, bluescopeIndication, hdmi_clock, hdmi_reset, defaultClock, defaultReset);
   MIMO#(1, 16, 64, Bit#(4)) mimo <- mkMIMO(MIMOConfiguration { unguarded: False, bram_based: False }, clocked_by hdmi_clock, reset_by hdmi_reset);
   Reg#(Bool) triggered <- mkReg(False, clocked_by hdmi_clock, reset_by hdmi_reset);
   rule toGearbox if ((hdmisignals.hdmi_vsync == 1) || triggered);
      Bit#(4) v = 0;
      v[0] = hdmisignals.hdmi_vsync;
      v[1] = hdmisignals.hdmi_de;
      v[2] = hdmisignals.hdmi_hsync;
      v[3] = hdmisignals.hdmi_vsync;
      triggered <= True;
      if (mimo.enqReadyN(1))
	 mimo.enq(1, cons(v,nil));
      else
	 $display("mimo.stalled mimo.count=%d", mimo.count);
   endrule
   rule gearboxToBlueScope if (mimo.deqReadyN(16));
      Bit#(64) v = pack(mimo.first());
      mimo.deq(16);
      bluescope.dataIn(v, v);
   endrule
`endif

   SyncFIFOIfc#(Bit#(64)) synchronizer <- mkSyncBRAMFIFO(1024, defaultClock, fifo_reset.new_rst, hdmi_clock, fifo_reset_hdmi);
   Reg#(Bool) evenOdd <- mkReg(True, clocked_by hdmi_clock, reset_by fifo_reset_hdmi);
   Reg#(Bit#(32)) savedPixelReg <- mkReg(0, clocked_by hdmi_clock, reset_by fifo_reset_hdmi);

   rule fromMemread;
      let v <- toGet(memreadEngine.dataPipes[0]).get;
      synchronizer.enq(v);
   endrule

   rule doPut;
      let pixel = savedPixelReg;
      if (evenOdd) begin
	 Vector#(2,Bit#(32)) doublePixel = unpack(synchronizer.first);
	 synchronizer.deq;
         savedPixelReg <= doublePixel[1];
	 pixel = doublePixel[0];
      end
      evenOdd <= !evenOdd;
      hdmiGen.pdata.put(pixel);
   endrule      

   Reg#(Bit#(32)) transferCount <- mkReg(0);
   Reg#(Bit#(32)) transferCyclesSnapshot <- mkReg(0);
   Reg#(Bit#(32)) transferCycles <- mkReg(0);
   Reg#(Bit#(48)) transferSumOfCycles<- mkReg(0);

   rule vsyncrule if (startDMA.pulse());
      fifo_reset.assertReset();
   endrule

   Reg#(Bool) traceTransfers <- mkReg(False);
   rule startTransfer if (startDMA.pulse() &&& referenceReg matches tagged Valid .reference);
      memreadEngine.readServers[0].request.put(MemengineCmd{sglId:reference, base:0, len:pack(extend(byteCountReg)), burstLen:64, tag: 0});
      if (traceTransfers)
	 hdmiDisplayIndication.transferStarted(transferCount);
      transferCyclesSnapshot <= transferCycles;
   endrule
   rule countCycles;
      transferCycles <= transferCycles + 1;
   endrule
   rule finishTransferRule;
      let b <- memreadEngine.readServers[0].response.get;
      transferCount <= transferCount + 1;
      let tc = transferCycles - transferCyclesSnapshot;
      transferSumOfCycles <= transferSumOfCycles + extend(tc);
      if (traceTransfers)
	 hdmiDisplayIndication.transferFinished(transferCount);
   endrule

    rule bozobit_rule;
        bozobit <= ~bozobit;
    endrule

    interface HdmiDisplayRequest displayRequest;
	method Action startFrameBuffer(Int#(32) base, UInt#(32) byteCount);
	   byteCountReg <= truncate(byteCount);
	   $display("startFrameBuffer %h", base);
           referenceReg <= tagged Valid truncate(pack(base));
	endmethod
       method Action stopFrameBuffer();
	  referenceReg <= tagged Invalid;
       endmethod
       method Action getTransferStats();
          hdmiDisplayIndication.transferStats(transferCount, transferCycles-transferCyclesSnapshot, extend(transferSumOfCycles));
       endmethod
       method Action setTraceTransfers(Bit#(1) trace);
	  traceTransfers <= unpack(trace);
       endmethod
    endinterface: displayRequest

    interface MemReadClient dmaClient = cons(memreadEngine.dmaClient, nil);
    interface HDMI hdmi = hdmisignals;
    interface HdmiGeneratorRequest internalRequest = hdmiGen.request;
`ifdef HDMI_BLUESCOPE
    interface BlueScopeRequest bluescopeRequest = bluescope.requestIfc;
    interface MemWriteClient bluescopeWriteClient = bluescope.writeClient;
`endif
    interface XADC xadc;
        method Bit#(4) gpio;
            return { bozobit, hdmisignals.hdmi_vsync,
                //hdmisignals.hdmi_data[8], hdmisignals.hdmi_data[0]};
                hdmisignals.hdmi_hsync, hdmisignals.hdmi_de};
        endmethod
    endinterface: xadc
endmodule
