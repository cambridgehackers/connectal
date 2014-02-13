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

   Reg#(DmaPointer)      rdPointer <- mkReg(0);
   Reg#(Bit#(32))           rdCnt <- mkReg(0);
   Reg#(Bit#(32))   mismatchCount <- mkReg(0);
   Reg#(Bit#(32))          srcGen <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) offset <- mkReg(0);
   
   Reg#(Bit#(8))         burstLen <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize))  delta <- mkReg(0);
   Reg#(Bit#(32)) iterCnt <- mkReg(0);
   
   let reqFifo <- mkFIFO;
   
   rule start_read if (rdCnt == 0 && srcGen == 0);
      Bit#(32) pointer = tpl_1(reqFifo.first);
      Bit#(32) numWords = tpl_2(reqFifo.first);
      Bit#(32) bl = tpl_3(reqFifo.first);
      rdPointer <= pointer;
      rdCnt <= numWords>>1;
      mismatchCount <= 0;
      srcGen <= numWords;
      offset <= 0;
      burstLen <= truncate(bl);
      delta <= 8*extend(bl);
      iterCnt <= iterCnt-1;
      if(iterCnt==1) 
	 reqFifo.deq;
      $display("start_read %d", iterCnt);
   endrule
   
   interface DmaReadClient dmaClient;
      interface GetF readReq;
	 method ActionValue#(DmaRequest) get() if (rdCnt > 0);
	    rdCnt <= rdCnt-extend(burstLen);
	    offset <= offset + delta;
	    //else if (rdCnt[5:0] == 6'b0)
	    //   indication.readReq(rdCnt);
	    return DmaRequest { pointer: rdPointer, offset: offset, burstLen: burstLen, tag: truncate(offset) };
	 endmethod
	 method Bool notEmpty();
	    return rdCnt > 0;
	 endmethod
      endinterface : readReq
      interface PutF readData;
	 method Action put(DmaData#(64) d);
	    //$display("readData  data=%h tag=%h",  d.data, d.tag);
	    let v = d.data;
	    let expectedV = {srcGen-1,srcGen};
	    let misMatch = v != expectedV;
	    mismatchCount <= mismatchCount + (misMatch ? 1 : 0);
	    srcGen <= srcGen-2;
	    if (srcGen == 2 && iterCnt == 0)
	       indication.readDone(mismatchCount);
	 endmethod
	 method Bool notFull();
	    return True;
	 endmethod
      endinterface : readData
   endinterface
   
   interface MemreadRequest request;
      method Action startRead(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) bl, Bit#(32) ic);
	 $display("mkMemRead::startRead(%d %d %d %d)", pointer, numWords, bl, ic);
	 indication.started(numWords*ic);
         reqFifo.enq(tuple3(pointer,numWords,bl));
	 iterCnt <= ic;
       endmethod
       method Action getStateDbg();
	  indication.reportStateDbg(rdCnt, mismatchCount);
       endmethod
   endinterface
endmodule
