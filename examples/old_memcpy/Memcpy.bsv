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
import BRAMFIFO::*;

import AxiClientServer::*;
import BlueScope::*;
import OldAxiDMA::*;

interface Memcpy;
    // copies numWords from srcPhys to dstPhys
    method Action memcpy(Bit#(32) dstPhys, Bit#(32) srcPhys, Bit#(32) numWords);
    method Action getSrcPhys();
    method Action setSrcPhys(Bit#(32) v);
    method Action getSrcLimit();
    method Action setSrcLimit(Bit#(32) v);
    method Action getDstPhys();
    method Action setDstPhys(Bit#(32) v);
    method Action getDstLimit();
    method Action setDstLimit(Bit#(32) v);
    method Action readWord(Bit#(32) phys);
    method Action getDataMismatch();
    method Action getDstCompPtr();
    method Action reset(Bit#(32) b);

    method Bit#(8) leds();
    method Action setLeds(Bit#(8) v);
    method Action setTriggerMaskValue(Bit#(8) mask, Bit#(8) value);
    method Action getTraceData();
    method Action getSampleCount();
    method Action startTrace();
    method Action clearTrace();
    method Action dataIn(Bit#(34) d, Bit#(8) t);
    interface Axi3Client#(64,8,6) m_axi;
    interface Axi3Client#(64,8,6) m_axi1;
endinterface

interface MemcpyIndications;
    method Action started();
    method Action started1(Bit#(32) srcPhysReg, Bit#(32) srcLimitReg, Bit#(32) dstPhysReg, Bit#(32) dstLimitReg);
    method Action srcPhys(Bit#(32) srcPhysReg);
    method Action srcLimit(Bit#(32) srcLimitReg);
    method Action dstPhys(Bit#(32) dstPhysReg);
    method Action dstLimit(Bit#(32) dstLimitReg);
    method Action src(Bit#(32) srcPhysReg);
    method Action dst(Bit#(32) dstPhysReg);
    method Action readWordResult(Bit#(32) phys, Bit#(64) v);
    method Action rData(Bit#(64) v);
    method Action done(Bit#(32) srcPhysReg);
    method Action traceData(Bit#(34) v);
    method Action sampleCount(Bit#(32) v);
    method Action dataMismatch(Bit#(32) v);
    method Action dstCompPtr(Bit#(32) v);
endinterface

module mkMemcpy#(MemcpyIndications indications)(Memcpy);
   AxiDMA dma <- mkAxiDMA;
   
   Reg#(Bit#(32)) readPhysAddrReg    <- mkReg(0);
   Reg#(Bit#(4)) rBurstCountReg1     <- mkReg(0);
   Reg#(Bit#(8)) ledsReg             <- mkReg(8'haa);
   BlueScope#(34,8) blueScope        <- mkBlueScope(1024);
   Reg#(Bit#(32)) traceDataRequested <- mkReg(0);
   
   rule done;
      dma.done;
      indications.done(dma.srcPhys);
      indications.dataMismatch(dma.dataMismatch ? 32'd1 : 32'd0);
   endrule   
   
   rule sendTraceData if (traceDataRequested > 0);
      traceDataRequested <= traceDataRequested - 1;
      let d <- blueScope.dataOut();
      indications.traceData(d);
   endrule
   
   method Action reset(Bit#(32) burstLen);
      dma.reset(truncate(burstLen));
   endmethod
   
   method Action getDstCompPtr();
      indications.dstCompPtr(dma.dstCompPtr);
   endmethod
   
   method Action getDataMismatch();
      indications.dataMismatch(dma.dataMismatch ? 32'd1 : 32'd0);
   endmethod
   
   method Action getSrcPhys();
      indications.srcPhys(dma.srcPhys);
   endmethod

   method Action setSrcPhys(Bit#(32) v);
      dma.srcPhys <= v;
   endmethod
   
   method Action getSrcLimit();
      indications.srcLimit(dma.srcLimit);
   endmethod

   method Action setSrcLimit(Bit#(32) v);
      indications.srcLimit(dma.srcLimit);
   endmethod

   method Action getDstPhys();
      indications.dstPhys(dma.dstPhys);
   endmethod

   method Action setDstPhys(Bit#(32) v);
      dma.dstPhys <= v;
   endmethod

   method Action getDstLimit();
      indications.dstLimit(dma.dstLimit);
   endmethod
   
   method Action setDstLimit(Bit#(32) v);
      dma.dstLimit <= v;
   endmethod

   method Action readWord(Bit#(32) phys);
      readPhysAddrReg <= phys;
   endmethod
   
   method Bit#(8) leds();
      return ledsReg;
   endmethod

   method Action setLeds(Bit#(8) v);
      ledsReg <= v;
   endmethod
   
   method Action memcpy(Bit#(32) dstPhys, Bit#(32) srcPhys, Bit#(32) numWords);
      dma.memcpy(dstPhys,srcPhys,numWords);
   endmethod
   
   method Action setTriggerMaskValue(Bit#(8) mask, Bit#(8) value);
      blueScope.setTriggerMask(mask);
      blueScope.setTriggerValue(value);
   endmethod

   method Action getTraceData();
      traceDataRequested <= traceDataRequested + 1;
   endmethod

   method Action startTrace();
      blueScope.start();
   endmethod

   method Action clearTrace();
      traceDataRequested <= 0;
      blueScope.clear();
   endmethod

   method Action dataIn(Bit#(34) d, Bit#(8) t);
      blueScope.dataIn(d, t);
   endmethod

   method Action getSampleCount();
      indications.sampleCount(blueScope.sampleCount);
   endmethod
   
   interface Axi3Client m_axi = dma.m_axi;
   interface Axi3Client m_axi1;
      interface Axi3ReadClient read;
	 method ActionValue#(Axi3ReadRequest#(6)) address() if (readPhysAddrReg != 0 && rBurstCountReg1 == 0);
	    rBurstCountReg1 <= 1;
	    return Axi3ReadRequest { address: readPhysAddrReg, burstLen: 0, id: 0} ;
	 endmethod
	 method Action data(Axi3ReadResponse#(64,6) response) if (rBurstCountReg1 != 0);
	    rBurstCountReg1 <= 0;
	    readPhysAddrReg <= 0;
	    indications.readWordResult(readPhysAddrReg, response.data);
	 endmethod
      endinterface
   endinterface
endmodule
