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
import GetPutF::*;
import Vector::*;

import Dma::*;

interface MemreadRequest;
   method Action startRead(Bit#(32) handle, Bit#(32) numWords, Bit#(32) burstLen);
   method Action getStateDbg();   
endinterface

interface Memread;
   interface MemreadRequest request;
   interface DmaReadClient#(64) dmaClient;
endinterface

interface MemreadIndication;
   method Action started(Bit#(32) numWords);
   method Action rData(Bit#(64) v);
   method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) mismatchCount);
   method Action readReq(Bit#(32) v);
   method Action readDone(Bit#(32) mismatchCount);
   method Action mismatch(Bit#(32) offset, Bit#(64) expectedValue, Bit#(64) value);
endinterface

module mkMemread#(MemreadIndication indication) (Memread);

   Reg#(DmaPointer) streamRdHandle <- mkReg(0);
   Reg#(Bit#(32)) streamRdCnt <- mkReg(0);
   Reg#(Bit#(32)) putOffset <- mkReg(0);
   Reg#(Bit#(32)) mismatchCount <- mkReg(0);
   Reg#(Bit#(32))      srcGen <- mkReg(0);
   Reg#(Bit#(DmaAddrSize))      offset <- mkReg(0);
   FIFOF#(Tuple3#(Bit#(32),Bit#(64),Bit#(64))) mismatchFifo <- mkSizedFIFOF(64);

   Reg#(Bit#(8)) burstLen <- mkReg(8);
   Reg#(Bit#(DmaAddrSize)) deltaOffset <- mkReg(8*8);

   rule mismatch;
      let tpl = mismatchFifo.first();
      mismatchFifo.deq();
      indication.mismatch(tpl_1(tpl), tpl_2(tpl), tpl_3(tpl));
   endrule

   interface MemreadRequest request;
       method Action startRead(Bit#(32) handle, Bit#(32) numWords, Bit#(32) bl) if (streamRdCnt == 0);
	  streamRdHandle <= handle;
	  streamRdCnt <= numWords>>1;
	  putOffset <= 0;
	  burstLen <= truncate(bl);
	  deltaOffset <= 8*truncate(bl);
	  indication.started(numWords);
       endmethod

       method Action getStateDbg();
	  indication.reportStateDbg(streamRdCnt, mismatchCount);
       endmethod
   endinterface

   interface DmaReadClient dmaClient;
      interface GetF readReq;
	 method ActionValue#(DmaRequest) get() if (streamRdCnt > 0 && mismatchFifo.notFull());
	    streamRdCnt <= streamRdCnt-extend(burstLen);
	    offset <= offset + deltaOffset;
	    if (streamRdCnt == extend(burstLen))
	       indication.readDone(mismatchCount);
	    //else if (streamRdCnt[5:0] == 6'b0)
	    //   indication.readReq(streamRdCnt);
	    return DmaRequest { handle: streamRdHandle, address: offset, burstLen: burstLen, tag: truncate(offset) };
	 endmethod
	 method Bool notEmpty();
	    return streamRdCnt > 0 && mismatchFifo.notFull();
	 endmethod
      endinterface : readReq
      interface PutF readData;
	 method Action put(DmaData#(64) d);
	    //$display("readData putOffset=%h d=%h tag=%h", putOffset, d.data, d.tag);
	    let v = d.data;
	    let expectedV = {srcGen+1,srcGen};
	    let misMatch = v != expectedV;
	    mismatchCount <= mismatchCount + (misMatch ? 1 : 0);
	    if (misMatch)
	       mismatchFifo.enq(tuple3(putOffset, expectedV, v));
	    srcGen <= srcGen+2;
	    putOffset <= putOffset + 8;
	    //indication.rData(v);
	 endmethod
	 method Bool notFull();
	    return mismatchFifo.notFull();
	 endmethod
      endinterface : readData
   endinterface
endmodule
