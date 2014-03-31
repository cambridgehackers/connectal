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
import GetPut::*;
import FIFO::*;

import PortalMemory::*;
import Dma::*;
import BlueScope::*;

interface MemcpyRequest;
   method Action startCopy(Bit#(32) wrPointer, Bit#(32) rdPointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
   method Action getStateDbg();   
endinterface

interface MemcpyIndication;
   method Action started(Bit#(32) numWords);
   method Action done(Bit#(32) dataMismatch);
   method Action rData(Bit#(64) v);
   method Action readReq(Bit#(32) v);
   method Action writeReq(Bit#(32) v);
   method Action writeAck(Bit#(32) v);
   method Action reportStateDbg(Bit#(32) rdCnt, Bit#(32) wrCnt, Bit#(32) dataMismatch);
endinterface

module mkMemcpyRequest#(MemcpyIndication indication,
			ObjectReadServer#(busWidth) dma_read_server,
			ObjectWriteServer#(busWidth) dma_write_server,
			BlueScope#(busWidth) bs)(MemcpyRequest)

   provisos (Div#(busWidth,8,busWidthBytes),
	     Add#(a__,64,busWidth),
	     Add#(b__,32,busWidth));

   let busWidthBytes = valueOf(busWidthBytes);
   let busWidthWords = busWidthBytes/4;

   Reg#(Bit#(32))         numWords <- mkReg(0);
   Reg#(Bit#(32))           srcGen <- mkReg(0);
   Reg#(Bit#(32))            rdCnt <- mkReg(0);
   Reg#(Bit#(32))            wrCnt <- mkReg(0);
   
   Reg#(Bit#(ObjectOffsetSize)) rdOff <- mkReg(0);
   Reg#(Bit#(ObjectOffsetSize)) wrOff <- mkReg(0);
   Reg#(Bit#(ObjectOffsetSize)) delta <- mkReg(0);

   Reg#(ObjectPointer)      rdPointer <- mkReg(0);
   Reg#(ObjectPointer)      wrPointer <- mkReg(0);

   Reg#(Bool)         dataMismatch <- mkReg(False);  
   Reg#(Bit#(8))          burstLen <- mkReg(0);
   
   Reg#(Bit#(32))        rdIterCnt <- mkReg(0);
   Reg#(Bit#(32))        wrIterCnt <- mkReg(0);

   FIFO#(Bool)             ackFIFO <- mkSizedFIFO(32);
   
   rule readReq(rdIterCnt > 0);
      if (rdCnt == numWords>>1) begin 
	 rdCnt <= 0;
	 rdIterCnt <= rdIterCnt-1;
	 rdOff <= 0;
      end
      else begin
	 //$display("rdReq: pointer=%d offset=%h burstlen=%d", rdPointer, rdOff, burstLen);
	 rdCnt <= rdCnt+extend(burstLen);
	 rdOff <= rdOff + delta;
	 dma_read_server.readReq.put(ObjectRequest {pointer: rdPointer, offset: rdOff, burstLen: extend(burstLen), tag: truncate(rdOff>>5)});
      end
   endrule
   
   rule writeReq(wrIterCnt > 0);
      if (wrCnt == numWords>>1) begin
	 wrCnt <= 0;
	 wrIterCnt <= wrIterCnt-1;
	 wrOff <= 0;
      end
      else begin
	 //$display("wrReq: pointer=%d offset=%h burstlen=%d", wrPointer, wrOff, burstLen);
	 wrCnt <= wrCnt+extend(burstLen);
	 wrOff <= wrOff + delta;
	 dma_write_server.writeReq.put(ObjectRequest {pointer: wrPointer, offset: wrOff, burstLen: extend(burstLen), tag: truncate(wrOff>>5)});
	 ackFIFO.enq(wrIterCnt == 1 && wrCnt == (numWords>>1)-extend(burstLen));
      end
   endrule
   
   Reg#(Bit#(32)) xx <- mkReg(0);
   
   rule writeAck;
      if (ackFIFO.first) begin
	 indication.done(dataMismatch ? 32'd1 : 32'd0);
	 $display("writeAck: xx=%d", xx);
      end
      let tag <- dma_write_server.writeDone.get();
      ackFIFO.deq;
   endrule
   
   rule loopback if (srcGen < numWords);
      xx <= xx+2;
      let tagdata <- dma_read_server.readData.get();
      let v = tagdata.data;
      Bool mismatch = False;
      for (Integer i = 0; i < busWidthWords; i = i+1)
	 mismatch = mismatch || (v[31+i*32:i*32] != (srcGen + fromInteger(i)));
      dataMismatch <= dataMismatch || mismatch;
      dma_write_server.writeData.put(tagdata);
      bs.dataIn(v,v);
      srcGen <= srcGen+fromInteger(busWidthWords);
      //$display("loopback %h", tagdata.data);
      //indication.rData(truncate(v));
   endrule
   
   rule rstSrcGen if (srcGen == numWords);
      srcGen <= 0;
   endrule
   
   method Action startCopy(Bit#(32) wp, Bit#(32) rp, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
      $display("startCopy wrPointer=%d rdPointer=%d numWords=%h burstLen=%d iterCnt=%d", wp, rp, nw, bl, ic);
      indication.started(nw);
      // initialized
      wrPointer <= wp;
      rdPointer <= rp;
      numWords  <= nw;
      burstLen <= truncate(bl);
      delta <= 8*extend(bl);
      rdIterCnt <= ic;
      wrIterCnt <= ic;
      // reset
      srcGen <= 0;
      rdCnt <= 0;
      wrCnt <= 0;
      rdOff <= 0;
      wrOff <= 0;
      dataMismatch <= False;
   endmethod

   method Action getStateDbg();
      indication.reportStateDbg(rdCnt, wrCnt, dataMismatch  ? 32'd1 : 32'd0);
   endmethod

endmodule
