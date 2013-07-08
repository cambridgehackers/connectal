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
import AxiClientServer::*;

interface Memcpy;
    // copies numWords from srcPhys to dstPhys
    method Action memcpy(Bit#(32) dstPhys, Bit#(32) srcPhys, Bit#(32) numWords);
    method Action reset(Bit#(32) burstCount);
    method Action getSrcPhys();
    method Action getSrcLimit();
    method Action getDstPhys();
    method Action getDstLimit();
    interface Axi3Client#(32,4,1) m_axi;
endinterface

interface MemcpyIndications;
    method Action started();
    method Action srcPhys(Bit#(32) srcPhysReg);
    method Action srcLimit(Bit#(32) srcLimitReg);
    method Action dstPhys(Bit#(32) dstPhysReg);
    method Action dstLimit(Bit#(32) dstLimitReg);
    method Action src(Bit#(32) srcPhysReg);
    method Action rData(Bit#(32) v);
    method Action wData(Bit#(32) v);
    method Action done(Bit#(32) srcPhysReg);
endinterface

module mkMemcpy#(MemcpyIndications indications)(Memcpy);
    Reg#(Bit#(32)) dstPhysReg <- mkReg(0);
    Reg#(Bit#(32)) dstLimitReg <- mkReg(0);
    Reg#(Bit#(32)) srcPhysReg <- mkReg(0);
    Reg#(Bit#(32)) srcLimitReg <- mkReg(0);
    Reg#(Bit#(4)) burstLenReg <- mkReg(8);
    Reg#(Bit#(4)) rBurstCountReg <- mkReg(0);
    Reg#(Bit#(4)) wBurstCountReg <- mkReg(0);
    FIFOF#(Bit#(32)) dataFifo <- mkSizedFIFOF(8);

    rule done if (srcPhysReg != 0 && srcPhysReg >= srcLimitReg);
        indications.done(srcPhysReg);
	srcPhysReg <= 0;
	srcLimitReg <= 0;
    endrule

    method Action reset(Bit#(32) burstLen);
        dstPhysReg <= 0;
	dstLimitReg <= 0;
	srcPhysReg <= 0;
	srcLimitReg <= 0;
	burstLenReg <= truncate(burstLen);
	rBurstCountReg <= 0;
	wBurstCountReg <= 0;
	dataFifo.clear();
    endmethod

    method Action getSrcPhys();
        indications.srcPhys(srcPhysReg);
    endmethod
    method Action getSrcLimit();
        indications.srcLimit(srcLimitReg);
    endmethod
    method Action getDstPhys();
        indications.dstPhys(dstPhysReg);
    endmethod
    method Action getDstLimit();
        indications.dstLimit(dstLimitReg);
    endmethod

    method Action memcpy(Bit#(32) dstPhys, Bit#(32) srcPhys, Bit#(32) numWords) if (srcPhysReg == 0);
        dstPhysReg <= dstPhys;
	dstLimitReg <= dstPhys + (numWords << 2);
        srcPhysReg <= srcPhys;
	Bit#(32) srcLimit = srcPhys + (numWords << 2);
        srcLimitReg <= srcLimit;
	indications.started();
    endmethod

    interface Axi3Client m_axi;
	interface Axi3ReadClient read;
	    method ActionValue#(Axi3ReadRequest#(1)) address() if (srcPhysReg < srcLimitReg && rBurstCountReg == 0);
		srcPhysReg <= srcPhysReg + (extend(burstLenReg)<<2);
		indications.src(srcPhysReg);
		rBurstCountReg <= burstLenReg;
		return Axi3ReadRequest { address: srcPhysReg, burstLen: burstLenReg-1, id: 0} ;
	    endmethod
	    method Action data(Axi3ReadResponse#(32,1) response) if (rBurstCountReg != 0);
	        if (rBurstCountReg == 1)
		begin
		    indications.rData(response.data);
		end
		rBurstCountReg <= rBurstCountReg - 1;
	        dataFifo.enq(response.data);
	    endmethod
	endinterface
	interface Axi3WriteClient write;
	    method ActionValue#(Axi3WriteRequest#(1)) address() if (dstPhysReg < dstLimitReg && wBurstCountReg == 0);
		dstPhysReg <= dstPhysReg + (extend(burstLenReg)<<2);
		wBurstCountReg <= burstLenReg;
	        return Axi3WriteRequest { address: dstPhysReg, burstLen: burstLenReg-1, id: 1 };
	    endmethod
	    method ActionValue#(Axi3WriteData#(32, 4, 1)) data() if (wBurstCountReg != 0);
	        dataFifo.deq;
		Bit#(1) last = 0;
		let v = dataFifo.first;

		if (wBurstCountReg == 1)
                begin
		    last = 1;
		    indications.wData(v);
		end
		wBurstCountReg <= wBurstCountReg - 1;

	        return Axi3WriteData { data: v, byteEnable: 4'b1111, last: last, id: 1 };
	    endmethod
	    method Action response(Axi3WriteResponse#(1) resp);
	    endmethod
	endinterface
    endinterface
endmodule
