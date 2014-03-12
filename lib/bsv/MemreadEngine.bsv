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

interface MemreadEngine#(numeric type busWidth);
   method Action start(DmaPointer pointer, Bit#(DmaOffsetSize) base, Bit#(32) readLen, Bit#(32) burstLen);
   method ActionValue#(Bool) finish();
   interface DmaReadClient#(busWidth) dmaClient;
endinterface

module mkMemreadEngine#(FIFOF#(Bit#(busWidth)) f) (MemreadEngine#(busWidth))
   
   provisos (Div#(busWidth,8,busWidthBytes));
   
   Reg#(Bit#(32))         numBeats <- mkReg(0);
   Reg#(Bit#(32))           reqCnt <- mkReg(0);
   Reg#(Bit#(32))          respCnt <- mkReg(0);
   
   Reg#(Bit#(DmaOffsetSize))   off <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) delta <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize))  base <- mkReg(0);

   Reg#(DmaPointer )       pointer <- mkReg(0);
   Reg#(Bit#(8))          burstLen <- mkReg(0);
   FIFO#(Bool)                  ff <- mkSizedFIFO(1);
   FIFO#(void)                  wf <- mkSizedFIFO(1);
   
   let bytes_per_beat = fromInteger(valueOf(busWidthBytes));

   method Action start(DmaPointer p, Bit#(DmaOffsetSize) b, Bit#(32) rl, Bit#(32) bl);
      numBeats <= rl/bytes_per_beat;
      reqCnt   <= 0;
      respCnt  <= 0;
      off      <= 0;
      delta    <= extend(bl);
      pointer  <= p;
      burstLen <= truncate(bl/bytes_per_beat);
      base     <= b;
      wf.enq(?);
   endmethod
   
   method ActionValue#(Bool) finish;
      wf.deq;
      ff.deq;
      return ff.first;
   endmethod
   
   interface DmaReadClient dmaClient;
      interface GetF readReq;
	 method ActionValue#(DmaRequest) get() if (reqCnt < numBeats);
	    reqCnt <= reqCnt+extend(burstLen);
	    off <= off + delta;
	    return DmaRequest { pointer: pointer, offset: off+base, burstLen: burstLen, tag: 0 };
	 endmethod
	 method Bool notEmpty();
	    return (reqCnt < numBeats);
	 endmethod
      endinterface
      interface PutF readData;
	 method Action put(DmaData#(busWidth) d);
	    respCnt <= respCnt+1;
	    if (respCnt+1 == numBeats)
	       ff.enq(True);
	    f.enq(d.data);
	    //$display("readData: tag=%d", d.tag);
	 endmethod
	 method Bool notFull();
	    return f.notFull;
	 endmethod
      endinterface
   endinterface   
endmodule
