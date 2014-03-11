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

interface MemwriteEngine#(numeric type busWidth);
   method Action start(DmaPointer pointer, Bit#(DmaOffsetSize) base, Bit#(32) writeLen, Bit#(32) burstLen);
   method ActionValue#(Bool) finish();
   interface DmaWriteClient#(busWidth) dmaClient;
endinterface

module  mkMemwriteEngine#(FIFOF#(Bit#(busWidth)) f) (MemwriteEngine#(busWidth))

   provisos (Div#(busWidth,8,busWidthBytes));

   Reg#(Bit#(32))         numBeats <- mkReg(0);
   Reg#(Bit#(32))           reqCnt <- mkReg(0);
   
   Reg#(Bit#(DmaOffsetSize))   off <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) delta <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize))  base <- mkReg(0);

   Reg#(DmaPointer)        pointer <- mkReg(0);
   Reg#(Bit#(8))          burstLen <- mkReg(0);
   FIFO#(Bool)                acks <- mkSizedFIFO(32);

   FIFOF#(Bool)                 ff <- mkSizedFIFOF(1);
   FIFOF#(void)                 wf <- mkSizedFIFOF(1);

   let bytes_per_beat = fromInteger(valueOf(busWidthBytes));
   
   method Action start(DmaPointer p, Bit#(DmaOffsetSize) b, Bit#(32) wl, Bit#(32) bl);
      numBeats <= wl/bytes_per_beat;
      reqCnt   <= 0;
      off      <= 0;
      delta    <= extend(bl);
      pointer  <= p;
      burstLen <= truncate(bl/bytes_per_beat);
      base     <= b;
      wf.enq(?);
   endmethod

   method ActionValue#(Bool) finish();
      wf.deq;
      ff.deq;
      return ff.first;
   endmethod

   interface DmaWriteClient dmaClient;
      interface GetF writeReq;
	 method ActionValue#(DmaRequest) get() if (reqCnt < numBeats);
	    reqCnt <= reqCnt+extend(burstLen);
	    off <= off + delta;
	    acks.enq(reqCnt+extend(burstLen) == numBeats);
	    return DmaRequest {pointer: pointer, offset: off+base, burstLen: burstLen, tag: 1};
	 endmethod
	 method Bool notEmpty;
	    return (reqCnt < numBeats);
	 endmethod
      endinterface
      interface GetF writeData;
	 method ActionValue#(DmaData#(busWidth)) get();
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
