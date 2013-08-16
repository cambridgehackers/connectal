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

interface AxiDMA;
   // user interface, limited to restrict use patterns
   method Action memcpy(Bit#(32) dstPhys, Bit#(32) srcPhys, Bit#(32) numWords);
   method Action reset(Bit#(4) burstLen);
   method Action done();
   interface Axi3Client#(64,8,6) m_axi;

   // debug registers might disappear in the future
   interface Reg#(Bit#(32)) srcPhys;
   interface Reg#(Bit#(32)) srcLimit;
   interface Reg#(Bit#(32)) dstPhys;
   interface Reg#(Bit#(32)) dstLimit;
   interface Reg#(Bit#(32)) dstCompPtr;
   interface Reg#(Bool)     dataMismatch;
endinterface

module mkAxiDMA(AxiDMA);
   Reg#(Bit#(32)) dstPhysReg    <- mkReg(0);
   Reg#(Bit#(32)) dstCompPtrReg <- mkReg(0);
   Reg#(Bit#(32)) dstLimitReg   <- mkReg(0);
   Reg#(Bit#(32)) srcPhysReg    <- mkReg(0);
   Reg#(Bit#(32)) srcLimitReg   <- mkReg(0);
   Reg#(Bit#(4)) burstLenReg    <- mkReg(8);
   Reg#(Bit#(4)) rBurstCountReg <- mkReg(0);
   Reg#(Bit#(4)) wBurstCountReg <- mkReg(0);
   Reg#(Bit#(32)) srcGen        <- mkReg(0);
   Reg#(Bool) dataMisMReg       <- mkReg(False);
   FIFOF#(Bit#(64)) dataFifo    <- mkSizedBRAMFIFOF(16);
   
   method Action memcpy(Bit#(32) dstPhys, Bit#(32) srcPhys, Bit#(32) numWords) if (srcPhysReg == 0);
      Bit#(32) srcLimit = srcPhys + (numWords << 2);
      Bit#(32) dstLimit = dstPhys + (numWords << 2);
      dstPhysReg    <= dstPhys;
      dstCompPtrReg <= dstPhys;
      dstLimitReg   <= dstLimit;
      srcPhysReg    <= srcPhys;
      srcLimitReg   <= srcLimit;
   endmethod

   method Action reset(Bit#(4) burstLen) if (srcPhysReg == 0);
      dstPhysReg     <= 0;
      dstCompPtrReg  <= 0;
      dstLimitReg    <= 0; 
      srcPhysReg     <= 0;
      srcLimitReg    <= 0;
      burstLenReg    <= burstLen;
      rBurstCountReg <= 0;
      wBurstCountReg <= 0;
      srcGen         <= 0;
      dataMisMReg    <= False;
      dataFifo.clear;
   endmethod

   method Action done if (srcPhysReg != 0 && srcPhysReg >= srcLimitReg && dstCompPtrReg >= dstLimitReg);
      srcPhysReg    <= 0;
      srcLimitReg   <= 0;
      dstCompPtrReg <= 0;
   endmethod   

   interface Axi3Client m_axi;
      interface Axi3ReadClient read;
	 method ActionValue#(Axi3ReadRequest#(6)) address() if (srcPhysReg < srcLimitReg && rBurstCountReg == 0);
	    srcPhysReg <= srcPhysReg + (extend(burstLenReg)<<3);
	    rBurstCountReg <= burstLenReg;
	    return Axi3ReadRequest { address: srcPhysReg, burstLen: burstLenReg-1, id: 0} ;
	 endmethod
	 method Action data(Axi3ReadResponse#(64,6) response) if (rBurstCountReg != 0);
	    rBurstCountReg <= rBurstCountReg - 1;
	    dataFifo.enq(response.data);
	    let misMatch0 = response.data[31:0] != srcGen;
	    let misMatch1 = response.data[63:32] != srcGen+1;
	    dataMisMReg <= dataMisMReg || misMatch0 || misMatch1;
	    srcGen <= srcGen+2;
	 endmethod
      endinterface
      interface Axi3WriteClient write;
	 method ActionValue#(Axi3WriteRequest#(6)) address() if (dstPhysReg < dstLimitReg && wBurstCountReg == 0);
	    let new_dstPhysReg = dstPhysReg + (extend(burstLenReg)<<3);
	    dstPhysReg <= new_dstPhysReg;
	    wBurstCountReg <= burstLenReg;
	    return Axi3WriteRequest { address: dstPhysReg, burstLen: burstLenReg-1, id: 1 };
	 endmethod
	 method ActionValue#(Axi3WriteData#(64, 8, 6)) data() if (wBurstCountReg != 0);
	    dataFifo.deq;
	    Bit#(1) last = wBurstCountReg == 1 ? 1'd1 : 1'd0; 
	    let v = dataFifo.first;
	    wBurstCountReg <= wBurstCountReg - 1;
	    return Axi3WriteData { data: v, byteEnable: maxBound, last: last, id: 1 };
	 endmethod
	 method Action response(Axi3WriteResponse#(6) resp);
	    dstCompPtrReg <= dstCompPtrReg + (extend(burstLenReg)<<3);
	 endmethod
      endinterface
   endinterface

   interface Reg srcPhys      = srcPhysReg;
   interface Reg srcLimit     = srcLimitReg;
   interface Reg dstPhys      = dstPhysReg;
   interface Reg dstLimit     = dstLimitReg;
   interface Reg dstCompPtr   = dstCompPtrReg;
   interface Reg dataMismatch = dataMisMReg;
endmodule
