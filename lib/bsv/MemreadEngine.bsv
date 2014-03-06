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

interface MemreadEngine;
   method Action start(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen);
   method ActionValue#(Bool) finished();
   interface DmaReadClient#(64) dmaClient;
endinterface

module mkMemreadEngine#(FIFOF#(Bit#(64)) f) (MemreadEngine);

   Reg#(Bit#(32))         numWords <- mkReg(0);
   Reg#(Bit#(32))           reqCnt <- mkReg(0);
   Reg#(Bit#(32))          respCnt <- mkReg(0);
   
   Reg#(Bit#(DmaOffsetSize))   off <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) delta <- mkReg(0);

   Reg#(DmaPointer )       pointer <- mkReg(0);
   Reg#(Bit#(8))          burstLen <- mkReg(0);
   FIFO#(Bool)                  ff <- mkSizedFIFO(1);
   FIFO#(void)                  wf <- mkSizedFIFO(1);
   
   method Action start(Bit#(32) p, Bit#(32) nw, Bit#(32) bl);
      numWords <= nw;
      reqCnt   <= 0;
      respCnt  <= 0;
      off      <= 0;
      delta    <= 8*extend(bl);
      pointer  <= p;
      burstLen <= truncate(bl);
      wf.enq(?);
   endmethod
   
   method ActionValue#(Bool) finished;
      wf.deq;
      ff.deq;
      return ff.first;
   endmethod
   
   interface DmaReadClient dmaClient;
      interface GetF readReq;
	 method ActionValue#(DmaRequest) get() if (reqCnt < numWords>>1);
	    reqCnt <= reqCnt+extend(burstLen);
	    off <= off + delta;
	    return DmaRequest { pointer: pointer, offset: off, burstLen: burstLen, tag: 1 };
	 endmethod
	 method Bool notEmpty();
	    return (reqCnt < numWords>>1);
	 endmethod
      endinterface
      interface PutF readData;
	 method Action put(DmaData#(64) d);
	    respCnt <= respCnt+1;
	    if (respCnt+1 == numWords>>1)
	       ff.enq(True);
	    f.enq(d.data);
	 endmethod
	 method Bool notFull();
	    return f.notFull;
	 endmethod
      endinterface
   endinterface   
endmodule
