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
import FIFO::*;
import GetPut::*;
import Assert::*;

import PortalMemory::*;
import Dma::*;

interface MemwriteEngine#(numeric type dataWidth);
   method Action start(ObjectPointer pointer, Bit#(ObjectOffsetSize) base, Bit#(32) writeLen, Bit#(32) burstLen);
   method ActionValue#(Bool) finish();
   interface ObjectWriteClient#(dataWidth) dmaClient;
endinterface

module mkMemwriteEngine#(Integer cmdQDepth, FIFOF#(Bit#(dataWidth)) f) (MemwriteEngine#(dataWidth))
   provisos (Div#(dataWidth,8,dataWidthBytes),
	     Mul#(dataWidthBytes,8,dataWidth),
	     Log#(dataWidthBytes,beatShift));

   Reg#(Bit#(32))             reqLen <- mkReg(0);
   Reg#(Bit#(32))            respCnt <- mkReg(0);
   
   Reg#(Bit#(32))                off <- mkReg(0);
   Reg#(Bit#(ObjectOffsetSize)) base <- mkReg(0);

   Reg#(ObjectPointer)       pointer <- mkReg(0);
   Reg#(Bit#(8))            burstLen <- mkReg(0);

   FIFOF#(Bool)                   ff <- mkSizedFIFOF(1);
   FIFOF#(Tuple2#(Bit#(32),Bit#(8))) wf <- mkSizedFIFOF(cmdQDepth);

   let beat_shift = fromInteger(valueOf(beatShift));
   
   method Action start(ObjectPointer p, Bit#(ObjectOffsetSize) b, Bit#(32) wl, Bit#(32) bl) if (off >= reqLen);
      dynamicAssert(bl[31:8]==0, "mkMemwriteEngine::start");
      reqLen   <= wl;
      off      <= 0;
      pointer  <= p;
      burstLen <= truncate(bl);
      base     <= b;
      wf.enq(tuple2(wl>>beat_shift,truncate(bl>>beat_shift))); 
   endmethod

   method ActionValue#(Bool) finish();
      ff.deq;
      return ff.first;
   endmethod

   interface ObjectWriteClient dmaClient;
      interface Get writeReq;
	 method ActionValue#(ObjectRequest) get() if (off < reqLen);
	    off <= off + extend(burstLen);
	    let bl = burstLen;
	    if (off + extend(burstLen) > reqLen)
	       bl = truncate(reqLen - off);
	    return ObjectRequest {pointer: pointer, offset: extend(off)+base, burstLen: bl, tag: 0};
	 endmethod
      endinterface
      interface Get writeData;
	 method ActionValue#(ObjectData#(dataWidth)) get();
	    f.deq;
	    return ObjectData{data:f.first, tag: 0};
	 endmethod
      endinterface
      interface Put writeDone;
	 method Action put(Bit#(6) tag);
	    let wl = tpl_1(wf.first);
	    let bl = tpl_2(wf.first);
	    if (respCnt+extend(bl) >= wl) begin
	       ff.enq(True);
	       respCnt <= 0;
	       wf.deq;
	    end
	    else begin
	       respCnt <= respCnt+extend(bl);
	    end
	 endmethod
      endinterface
   endinterface

endmodule
