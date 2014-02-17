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
import GetPutF::*;
import Vector::*;

import Dma::*;

interface MemreadRequest;
   method Action startRead(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
   method Action getStateDbg();   
endinterface

interface Memread;
   interface MemreadRequest request;
   interface DmaReadClient#(64) dmaClient;
endinterface

interface MemreadIndication;
   method Action started(Bit#(32) numWords);
   method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) mismatchCount);
   method Action readReq(Bit#(32) v);
   method Action readDone(Bit#(32) mismatchCount);
endinterface

module mkMemread#(MemreadIndication indication) (Memread);

   Reg#(Bit#(32))         numWords <- mkReg(0);
   Reg#(Bit#(32))           srcGen <- mkReg(0);
   Reg#(Bit#(32))            rdCnt <- mkReg(0);
   
   Reg#(Bit#(DmaOffsetSize)) rdOff <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) delta <- mkReg(0);

   Reg#(DmaPointer)      rdPointer <- mkReg(0);

   Reg#(Bool)         dataMismatch <- mkReg(False);  
   Reg#(Bit#(8))          burstLen <- mkReg(0);
   
   Reg#(Bit#(32))        rdIterCnt <- mkReg(0);
   Reg#(Bit#(32))    mismatchCount <- mkReg(0);
   
   rule readReq (rdIterCnt > 0 && rdCnt == numWords>>1);
      rdCnt <= 0;
      rdIterCnt <= rdIterCnt-1;
      rdOff <= 0;
   endrule
   
   interface DmaReadClient dmaClient;
      interface GetF readReq;
	 method ActionValue#(DmaRequest) get() if (rdIterCnt > 0 && rdCnt < numWords>>1);
	    //$display("rdReq: pointer=%d offset=%h burstlen=%d", rdPointer, rdOff, burstLen);
	    rdCnt <= rdCnt+extend(burstLen);
	    rdOff <= rdOff + delta;
	    return DmaRequest { pointer: rdPointer, offset: rdOff, burstLen: burstLen, tag: 1 };
	 endmethod
	 method Bool notEmpty();
	    return (rdIterCnt > 0 && rdCnt < numWords>>1);
	 endmethod
      endinterface : readReq
      interface PutF readData;
	 method Action put(DmaData#(64) d);
	    //$display("readData  data=%h tag=%h",  d.data, d.tag);
	    let v = d.data;
	    let expectedV = {srcGen+1,srcGen};
	    let misMatch = v != expectedV;
	    mismatchCount <= mismatchCount + (misMatch ? 1 : 0);
	    if (srcGen+2 == numWords)
	       srcGen <= 0;
	    else
	       srcGen <= srcGen+2;
	    if (srcGen+2 == numWords && rdIterCnt == 0)
	       indication.readDone(mismatchCount);
	 endmethod
	 method Bool notFull();
	    return True;
	 endmethod
      endinterface : readData
   endinterface
   
   interface MemreadRequest request;
      method Action startRead(Bit#(32) rp, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
	 $display("startRead rdPointer=%d numWords=%h burstLen=%d iterCnt=%d", rp, nw, bl, ic);
	 indication.started(nw);
	 // initialized
	 rdPointer <= rp;
	 numWords        <= nw;
	 burstLen <= truncate(bl);
	 delta <= 8*extend(bl);
	 rdIterCnt <= ic;
	 // reset
	 srcGen <= 0;
	 rdCnt <= 0;
	 rdOff <= 0;
	 dataMismatch <= False;
      endmethod
      method Action getStateDbg();
	 indication.reportStateDbg(rdCnt, mismatchCount);
      endmethod
   endinterface
endmodule
