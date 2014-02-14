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
import BlueScope::*;

interface MemcpyRequest;
   method Action startCopy(Bit#(32) wrPointer, Bit#(32) rdPointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
   method Action readWord();
   method Action getStateDbg();   
endinterface

interface MemcpyIndication;
   method Action started(Bit#(32) numWords);
   method Action readWordResult(Bit#(32) v);
   method Action done(Bit#(32) dataMismatch);
   method Action rData(Bit#(64) v);
   method Action readReq(Bit#(32) v);
   method Action writeReq(Bit#(32) v);
   method Action writeAck(Bit#(32) v);
   method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) streamWrCnt, Bit#(32) dataMismatch);
endinterface

module mkMemcpyRequest#(MemcpyIndication indication,
			DmaReadServer#(busWidth) dma_stream_read_server,
			DmaWriteServer#(busWidth) dma_stream_write_server,
			DmaReadServer#(busWidth) dma_word_read_server,
			BlueScope#(busWidth) bs)(MemcpyRequest)

   provisos (Div#(busWidth,8,busWidthBytes),
	     Add#(a__,32,busWidth));

   let busWidthBytes = valueOf(busWidthBytes);
   let busWidthWords = busWidthBytes/4;

   Reg#(Bit#(32))      srcGen <- mkReg(0);
   Reg#(Bit#(32)) streamRdCnt <- mkReg(0);
   Reg#(Bit#(32)) streamWrCnt <- mkReg(0);
   Reg#(Bit#(32)) streamAckCnt <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) streamRdOff <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) streamWrOff <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize))  delta <- mkReg(0);
   Reg#(DmaPointer)    streamRdPointer <- mkReg(0);
   Reg#(DmaPointer)    streamWrPointer <- mkReg(0);
   Reg#(DmaPointer) bluescopeWrPointer <- mkReg(0);
   Reg#(Bool)              dataMismatch <- mkReg(False);  
   Reg#(Bit#(8)) burstLen <- mkReg(0);
   
   let                  reqFifo <- mkFIFO;
   Reg#(Bit#(32))       iterCnt <- mkReg(0);
   
   rule start_copy  if (streamRdCnt == 0 && streamWrCnt == 0);
      Bit#(32) wrPointer = tpl_1(reqFifo.first);
      Bit#(32) rdPointer = tpl_2(reqFifo.first);
      Bit#(32) numWords  = tpl_3(reqFifo.first);
      Bit#(32) bl        = tpl_4(reqFifo.first);

      streamRdOff <= 0;
      streamWrOff <= 0;

      streamWrPointer <= wrPointer;
      streamRdPointer <= rdPointer;
      
      burstLen <= truncate(bl);
      delta <= 8*extend(bl);
      
      streamRdCnt <= numWords>>1;
      streamWrCnt <= numWords>>1;
      streamAckCnt <= numWords>>1;

      iterCnt <= iterCnt-1;
      if(iterCnt ==1)
	 reqFifo.deq;
      $display("start_copy %d", iterCnt);
   endrule
   
   rule readReq(streamRdCnt > 0);
      streamRdCnt <= streamRdCnt-extend(burstLen);
      streamRdOff <= streamRdOff + delta;
      //$display("readReq.put pointer=%h address=%h, burstlen=%h", streamRdPointer, streamRdOff, burstLen);
      dma_stream_read_server.readReq.put(DmaRequest {pointer: streamRdPointer, offset: streamRdOff, burstLen: extend(burstLen), tag: truncate(streamRdOff>>5)});
      //indication.readReq(streamRdCnt);
   endrule

   rule writeReq(streamWrCnt > 0);
      streamWrCnt <= streamWrCnt-extend(burstLen);
      streamWrOff <= streamWrOff + delta;
      //$display("writeReq.put pointer=%h address=%h", streamWrPointer, streamWrOff);
      dma_stream_write_server.writeReq.put(DmaRequest {pointer: streamWrPointer, offset: streamWrOff, burstLen: extend(burstLen), tag: truncate(streamWrOff>>5)});
      //indication.writeReq(streamWrCnt);
   endrule
   
   rule writeAck;
      let tag <- dma_stream_write_server.writeDone.get();
      //$display("writeAck: tag=%d", tag);
      streamAckCnt <= streamAckCnt-extend(burstLen);
      //indication.writeAck(streamAckCnt);
      if(streamAckCnt==extend(burstLen) && iterCnt == 0)
   	 indication.done(dataMismatch ? 32'd1 : 32'd0);
   endrule

   rule loopback;
      let tagdata <- dma_stream_read_server.readData.get();
      let v = tagdata.data;
      Bool mismatch = False;
      for (Integer i = 0; i < busWidthWords; i = i+1)
	 mismatch = mismatch || (v[31+i*32:i*32] != (srcGen + fromInteger(i)));
      dataMismatch <= dataMismatch || mismatch;
      dma_stream_write_server.writeData.put(tagdata);
      bs.dataIn(v,v);
      srcGen <= srcGen+fromInteger(busWidthWords);
      //$display("loopback %h", tagdata.data);
      // indication.rData(v);
   endrule
   
   rule readWordResp;
      let tagdata <- dma_word_read_server.readData.get;
      indication.readWordResult(truncate(tagdata.data));
   endrule
   
   method Action startCopy(Bit#(32) wrPointer, Bit#(32) rdPointer, Bit#(32) numWords, Bit#(32) bl, Bit#(32) ic);
      $display("startCopy wrPointer=%h rdPointer=%h numWords=%d burstLen=%d iterCnt=%d", wrPointer, rdPointer, numWords, bl, ic);
      indication.started(numWords);
      reqFifo.enq(tuple4(wrPointer, rdPointer, numWords, bl));
      iterCnt <= ic;
   endmethod

   method Action readWord();
      dma_word_read_server.readReq.put(DmaRequest {pointer: streamWrPointer, offset: 0, burstLen: 1, tag: 1});
   endmethod

   method Action getStateDbg();
      indication.reportStateDbg(streamRdCnt, streamWrCnt, dataMismatch  ? 32'd1 : 32'd0);
   endmethod

endmodule
