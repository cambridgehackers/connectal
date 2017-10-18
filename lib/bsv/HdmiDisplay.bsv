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
`include "ConnectalProjectConfig.bsv"
import FIFO::*;
import BRAMFIFO::*;
import Vector::*;
import Clocks::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;
import ConnectalMemTypes::*;
import MemReadEngine::*;
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
   method Action transferFinished(Bit#(32) count, Bit#(32) byteLen);
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

typedef 3 NumOutstandingRequests;
typedef 64 FrameBufferBurstLenInBytes;

module mkHdmiDisplay#(Clock hdmi_clock,
		      HdmiDisplayIndication hdmiDisplayIndication,
		      HdmiGeneratorIndication hdmiGeneratorIndication
`ifdef HDMI_BLUESCOPE
		      , BlueScopeIndication bluescopeIndication
`endif
                      )(HdmiDisplay);
   let verbose = False;
   Clock defaultClock <- exposeCurrentClock;
   Reset defaultReset <- exposeCurrentReset;
   Reset hdmi_reset <- mkAsyncReset(2, defaultReset, hdmi_clock);
   MakeResetIfc fifo_reset <- mkReset(2, True, defaultClock);
   Reset fifo_reset_hdmi <- mkAsyncReset(2, fifo_reset.new_rst, hdmi_clock);

   Reg#(UInt#(24)) byteCountReg <- mkReg(1080*1920);
   Reg#(Bit#(24)) frameByte <- mkReg(99, clocked_by hdmi_clock, reset_by hdmi_reset);
   Reg#(Bit#(24)) frameByteSaved <- mkSyncReg(1234, hdmi_clock, hdmi_reset, defaultClock);
   Reg#(Bool) frameByteReady <- mkReg(False, clocked_by hdmi_clock, reset_by hdmi_reset);

   Reg#(Bool) sendVsyncIndication <- mkReg(False);
   SyncPulseIfc startDMA <- mkSyncHandshake(hdmi_clock, hdmi_reset, defaultClock);
   Reg#(Bit#(1)) bozobit <- mkReg(0, clocked_by hdmi_clock, reset_by hdmi_reset);

   Reg#(Maybe#(Bit#(32))) referenceReg <- mkReg(tagged Invalid);
   MemReadEngine#(64,64,NumOutstandingRequests,1) memreadEngine <- mkMemReadEngine;

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
   rule toSaved if (hdmisignals.hdmi_vsync == 1);
      if (frameByteReady && frameByte != 0) begin
         frameByteSaved <= frameByte;
         frameByte <= 0;
      end
      frameByteReady <= False;
   endrule
   rule endsync if (hdmisignals.hdmi_vsync != 1);
      frameByteReady <= True;
   endrule

   SyncFIFOIfc#(Bit#(64)) synchronizer <- mkSyncBRAMFIFO(1024, defaultClock, fifo_reset.new_rst, hdmi_clock, fifo_reset_hdmi);
   //SyncFIFOIfc#(Bit#(64)) synchronizer <- mkSyncFIFO(16, defaultClock, fifo_reset.new_rst, hdmi_clock);
   Reg#(Bool) evenOdd <- mkReg(True, clocked_by hdmi_clock, reset_by fifo_reset_hdmi);
   Reg#(Bit#(32)) savedPixelReg <- mkReg(0, clocked_by hdmi_clock, reset_by fifo_reset_hdmi);

   Reg#(Bit#(32)) transferCount <- mkReg(0);
   Reg#(Bit#(32)) transferCyclesSnapshot <- mkReg(0);
   Reg#(Bit#(32)) transferCycles <- mkReg(0);
   Reg#(Bit#(48)) transferSumOfCycles<- mkReg(0);
   Reg#(UInt#(24)) transferWord <- mkReg(0);
   Reg#(Bit#(32)) transferLast <- mkReg(0);
   ClockDividerIfc slowClock <- mkClockDivider(64);
   Reset slowReset <- mkAsyncReset(2, defaultReset, slowClock.slowClock);
   SyncPulseIfc dmastartPulse <- mkSyncPulse(defaultClock, defaultReset, slowClock.slowClock);
   SyncPulseIfc dmaendPulse <- mkSyncPulse(defaultClock, defaultReset, slowClock.slowClock);
   Reg#(Bool) dmastart <- mkReg(False, clocked_by slowClock.slowClock, reset_by slowReset);
   Reg#(Bool) dmaend <- mkReg(False, clocked_by slowClock.slowClock, reset_by slowReset);
   Reg#(Bool) dmaendDelay <- mkReg(False, clocked_by slowClock.slowClock, reset_by slowReset);
   Reg#(Bit#(3)) dmaCount <- mkReg(0);
   Reg#(Bool) traceTransfers <- mkReg(False);
   Reg#(Bool) dumpstarted <- mkReg(False);
   Reg#(Bool) dumpover <- mkReg(False);
   Reg#(Bool) duringDma <- mkReg(False);
   //Reg#(Bool) dmaReady <- mkReg(False);
   FIFO#(void)  doneFifo <- mkFIFO;

   rule dmaPulserule;
      dmastart <= dmastartPulse.pulse;
      dmaend <= dmaendPulse.pulse;
      dmaendDelay <= dmaend;
   endrule
   rule fromMemread;
      let v <- toGet(memreadEngine.readServers[0].data).get;
      synchronizer.enq(v.data);
      if (verbose)
          $display("hdmiDisplay: dmadata [%d]=%x cycle %d", transferWord, v.data, transferCycles - transferCyclesSnapshot);
      transferWord <= transferWord + 1;
      transferLast <= transferCycles;
      if (v.last)
         doneFifo.enq(?);
   endrule

   rule doPut1 if (evenOdd);
      Vector#(2,Bit#(32)) doublePixel = unpack(synchronizer.first);
      synchronizer.deq;
      savedPixelReg <= doublePixel[1];
      frameByte <= frameByte + 1;
      //if (dmaReady) begin
         //if (verbose)
            //$display("hdmiDisplay: SKIP     sync.deq %x:%x cycle %d", doublePixel[0], doublePixel[1], transferCycles - transferCyclesSnapshot);
      //end
      //else begin
         if (verbose)
            $display("hdmiDisplay: even     sync.deq %x:%x cycle %d", doublePixel[0], doublePixel[1], transferCycles - transferCyclesSnapshot);
         hdmiGen.pdata.put(doublePixel[0]);
         evenOdd <= !evenOdd;
      //end
   endrule      
   rule doPut2 if (!evenOdd);
      if (verbose)
          $display("hdmiDisplay:     odd                             cycle %d", transferCycles - transferCyclesSnapshot);
      hdmiGen.pdata.put(savedPixelReg);
      evenOdd <= !evenOdd;
   endrule      

   rule vsyncrule if (startDMA.pulse());
      fifo_reset.assertReset();
   endrule

   rule startTransfer if (startDMA.pulse() &&& referenceReg matches tagged Valid .reference);
   //   /dmaReady <= True;
   ///endrule
   //rule startd if (dmaReady && !duringDma &&& referenceReg matches tagged Valid .reference);
      memreadEngine.readServers[0].request.put(MemengineCmd{sglId:reference, base:0, len:pack(extend(byteCountReg)), burstLen:fromInteger(valueOf(FrameBufferBurstLenInBytes)), tag: 0});
      if (traceTransfers)
	 hdmiDisplayIndication.transferStarted(transferCount);
      transferCyclesSnapshot <= transferCycles;
      transferWord <= 0;
      $display("hdmiDisplay: startdma %d residual %d gap %d", transferCycles - transferCyclesSnapshot,
           byteCountReg - 8 * transferWord, transferCycles - transferLast);
      dmastartPulse.send();
      dmaCount <= dmaCount + 1;
      if (dmaCount == 7 && !dumpover) begin
         $dumpoff;
         dumpover <= True;
      end
      //dmaReady <= False;
      duringDma <= True;
   endrule
   rule countCycles;
      transferCycles <= transferCycles + 1;
   endrule
   rule finishTransferRule;
      doneFifo.deq;
      transferCount <= transferCount + 1;
      let tc = transferCycles - transferCyclesSnapshot;
      transferSumOfCycles <= transferSumOfCycles + extend(tc);
      if (traceTransfers)
	 hdmiDisplayIndication.transferFinished(transferCount, extend(frameByteSaved));
      $display("hdmiDisplay: enddma %d", transferCycles - transferCyclesSnapshot);
      dmaendPulse.send();
      duringDma <= False;
      if (!dumpstarted) begin
         //$dumpfile("dump.vcd");
         $dumpvars;
         $dumpon;
         $display("VCDDUMP starting");
         dumpstarted <= True;
      end
   endrule

    rule bozobit_rule;
        bozobit <= ~bozobit;
    endrule

    interface HdmiDisplayRequest displayRequest;
	method Action startFrameBuffer(Int#(32) base, UInt#(32) byteCount);
	   byteCountReg <= truncate(byteCount);
	   $display("startFrameBuffer base %x count %d", base, byteCount);
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
