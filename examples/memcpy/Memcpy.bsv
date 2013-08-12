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

interface Memcpy;
    // copies numWords from srcPhys to dstPhys
    method Action memcpy(Bit#(32) dstPhys, Bit#(32) srcPhys, Bit#(32) numWords);
    method Action reset(Bit#(32) burstCount);
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
    Reg#(Bit#(5)) tagCntReg <- mkReg(0);
    Reg#(Bit#(32)) dstPhysReg <- mkReg(0);
    Reg#(Bit#(32)) dstCompPtr <- mkReg(0);
    Reg#(Bit#(32)) dstLimitReg <- mkReg(0);
    Reg#(Bit#(32)) srcPhysReg <- mkReg(0);
    Reg#(Bit#(32)) srcLimitReg <- mkReg(0);
    Reg#(Bit#(32)) readPhysAddrReg <- mkReg(0);
    Reg#(Bit#(4)) burstLenReg <- mkReg(8);
    Reg#(Bit#(4)) rBurstCountReg <- mkReg(0);
    Reg#(Bit#(4)) wBurstCountReg <- mkReg(0);
    Reg#(Bit#(4)) rBurstCountReg1 <- mkReg(0);
    Reg#(Bit#(8)) ledsReg <- mkReg(8'haa);
    FIFOF#(Bit#(64)) dataFifo <- mkSizedBRAMFIFOF(8);
    BlueScope#(34,8) blueScope <- mkBlueScope(1024);
    Reg#(Bit#(32)) traceDataRequested <- mkReg(0);
    Reg#(Bit#(32)) srcGen <- mkReg(0);
    Reg#(Bool) dataMismatch <- mkReg(False);
   
    rule done if (srcPhysReg != 0 && srcPhysReg >= srcLimitReg && dstCompPtr >= dstLimitReg);
        indications.done(srcPhysReg);
        indications.dataMismatch(dataMismatch ? 32'd1 : 32'd0);
	srcPhysReg <= 0;
        srcLimitReg <= 0;
        dstCompPtr <= 0;
    endrule   

    rule sendTraceData if (traceDataRequested > 0);
        traceDataRequested <= traceDataRequested - 1;
	let d <- blueScope.dataOut();
        indications.traceData(d);
    endrule

    method Action reset(Bit#(32) burstLen);
	dstPhysReg <= 0;
        dstCompPtr <= 0;
        dstLimitReg <= 0;
	srcPhysReg <= 0;
	srcLimitReg <= 0;
	burstLenReg <= truncate(burstLen);
	rBurstCountReg <= 0;
	wBurstCountReg <= 0;
	dataFifo.clear();
    endmethod

   
   method Action getDstCompPtr();
      indications.dstCompPtr(dstCompPtr);
   endmethod
   method Action getDataMismatch();
      indications.dataMismatch(dataMismatch ? 32'd1 : 32'd0);
   endmethod
   
    method Action getSrcPhys();
        indications.srcPhys(srcPhysReg);
    endmethod
    method Action setSrcPhys(Bit#(32) v);
        srcPhysReg <= v;
        indications.srcPhys(srcPhysReg);
    endmethod
    method Action getSrcLimit();
        indications.srcLimit(srcLimitReg);
    endmethod
    method Action setSrcLimit(Bit#(32) v);
        srcLimitReg <= v;
        indications.srcLimit(srcLimitReg);
    endmethod
    method Action getDstPhys();
        indications.dstPhys(dstPhysReg);
    endmethod
    method Action setDstPhys(Bit#(32) v);
        dstPhysReg <= v;
        indications.dstPhys(dstPhysReg);
    endmethod
    method Action getDstLimit();
        indications.dstLimit(dstLimitReg);
    endmethod
    method Action setDstLimit(Bit#(32) v);
        dstLimitReg <= v;
        indications.dstLimit(dstLimitReg);
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

    method Action memcpy(Bit#(32) dstPhys, Bit#(32) srcPhys, Bit#(32) numWords) if (srcPhysReg == 0);
        Bit#(32) srcLimit = srcPhys + (numWords << 2);
        Bit#(32) dstLimit = dstPhys + (numWords << 2);
        dstPhysReg <= dstPhys;
        dstCompPtr <= dstPhys;
	dstLimitReg <= dstLimit;
        srcPhysReg <= srcPhys;
        srcLimitReg <= srcLimit;
        indications.started();
        indications.started1(srcPhys, srcLimit, dstPhys, dstLimit);
        dataMismatch <= False;
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

    interface Axi3Client m_axi;
	interface Axi3ReadClient read;
	    method ActionValue#(Axi3ReadRequest#(6)) address() if (srcPhysReg < srcLimitReg && rBurstCountReg == 0);
		srcPhysReg <= srcPhysReg + (extend(burstLenReg)<<3);
		// indications.src(srcPhysReg);
		rBurstCountReg <= burstLenReg;
		return Axi3ReadRequest { address: srcPhysReg, burstLen: burstLenReg-1, id: 0} ;
	    endmethod
	    method Action data(Axi3ReadResponse#(64,6) response) if (rBurstCountReg != 0);
	       // indications.rData(response.data);
	       if (rBurstCountReg == 1)
		  begin
		     noAction;
		  end
	       rBurstCountReg <= rBurstCountReg - 1;
	       dataFifo.enq(response.data);
	       let misMatch0 = response.data[31:0] != srcGen;
	       let misMatch1 = response.data[63:32] != srcGen+1;
	       dataMismatch <= dataMismatch || misMatch0 || misMatch1;
	       srcGen <= srcGen+2;
	    endmethod
	endinterface
	interface Axi3WriteClient write;
	   method ActionValue#(Axi3WriteRequest#(6)) address() if (dstPhysReg < dstLimitReg && wBurstCountReg == 0);
		// indications.dst(dstPhysReg);
	        let new_dstPhysReg = dstPhysReg + (extend(burstLenReg)<<3);
	        dstPhysReg <= new_dstPhysReg;
                // The AXI spec indicates that transactions with the same ID must be comitted in order.
	        // The only reason then to use a different ID for each transaction would be if we wanted
	        // to give the memory subsystem leeway to committ writes out of order, which I don't think
	        // it can anyways.   I tried this and the system hung (mdk)
	        Bit#(6) tag = 6'b1; 
                tagCntReg <= tagCntReg+1;
	        wBurstCountReg <= burstLenReg;
	        return Axi3WriteRequest { address: dstPhysReg, burstLen: burstLenReg-1, id: tag };
	    endmethod
	    method ActionValue#(Axi3WriteData#(64, 8, 6)) data() if (wBurstCountReg != 0);
	        dataFifo.deq;
		Bit#(1) last = 0;
		let v = dataFifo.first;
		if (wBurstCountReg == 1)
                begin
		    last = 1;
		end
		wBurstCountReg <= wBurstCountReg - 1;
	        return Axi3WriteData { data: v, byteEnable: maxBound, last: last, id: 1 };
	    endmethod
	    method Action response(Axi3WriteResponse#(6) resp);
	        dstCompPtr <= dstCompPtr + (extend(burstLenReg)<<3);
	    endmethod
	endinterface
    endinterface
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
