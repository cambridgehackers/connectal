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

import Vector::*;
import FIFOF::*;
import GetPutF::*;
import FIFO::*;

import PortalMemory::*;
import Dma::*;

interface MemwriteEngine;
   method Action start(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen);
   method ActionValue#(Bool) finished();
   interface DmaWriteClient#(64) dmaClient;
endinterface

module  mkMemwriteEngine#(FIFOF#(Bit#(64)) f) (MemwriteEngine);

   Reg#(Bit#(32))         numWords <- mkReg(0);
   Reg#(Bit#(32))           reqCnt <- mkReg(0);
   
   Reg#(Bit#(DmaOffsetSize))   off <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) delta <- mkReg(0);

   Reg#(DmaPointer)        pointer <- mkReg(0);
   Reg#(Bit#(8))          burstLen <- mkReg(0);
   FIFO#(Bool)                acks <- mkSizedFIFO(32);

   FIFOF#(Bool)                 ff <- mkSizedFIFOF(1);
   FIFOF#(void)                 wf <- mkSizedFIFOF(1);
   
   method Action start(Bit#(32) p, Bit#(32) nw, Bit#(32) bl);
      numWords <= nw;
      reqCnt <= 0;
      off <= 0;
      delta <= 8*extend(bl);
      pointer <= p;
      burstLen <= truncate(bl);
      wf.enq(?);
   endmethod

   method ActionValue#(Bool) finished();
      wf.deq;
      ff.deq;
      return ff.first;
   endmethod

   interface DmaWriteClient dmaClient;
      interface GetF writeReq;
	 method ActionValue#(DmaRequest) get() if (reqCnt < numWords>>1);
	    reqCnt <= reqCnt+extend(burstLen);
	    off <= off + delta;
	    acks.enq(reqCnt+extend(burstLen) == (numWords>>1));
	    return DmaRequest {pointer: pointer, offset: off, burstLen: burstLen, tag: 1};
	 endmethod
	 method Bool notEmpty;
	    return (reqCnt < numWords>>1);
	 endmethod
      endinterface
      interface GetF writeData;
	 method ActionValue#(DmaData#(64)) get();
	    f.deq;
	    return DmaData{data:f.first, tag: 1};
	 endmethod
	 method Bool notEmpty;
	    return f.notEmpty;
	 endmethod
      endinterface
      interface PutF writeDone;
	 method Action put(Bit#(6) tag);
	    if (acks.first)
	       ff.enq(True);
	    acks.deq;
	 endmethod
	 method Bool notFull;
	    return acks.first ? ff.notFull : True;
	 endmethod
      endinterface
   endinterface

endmodule
