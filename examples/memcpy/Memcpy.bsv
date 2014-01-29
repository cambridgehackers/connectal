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

import PortalMemory::*;
import Dma::*;
import BlueScope::*;

interface MemcpyRequest;
   method Action startCopy(Bit#(32) wrHandle, Bit#(32) rdHandle, Bit#(32) numWords);
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
   method Action reportStateDbg(Bit#(32) srcGen, Bit#(32) streamRdCnt, Bit#(32) streamWrCnt, Bit#(32) writeInProg, Bit#(32) dataMismatch);
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
   Reg#(Bit#(DmaAddrSize)) streamRdOff <- mkReg(0);
   Reg#(Bit#(DmaAddrSize)) streamWrOff <- mkReg(0);
   Reg#(DmaPointer)    streamRdHandle <- mkReg(0);
   Reg#(DmaPointer)    streamWrHandle <- mkReg(0);
   Reg#(DmaPointer) bluescopeWrHandle <- mkReg(0);
   Reg#(Bool)               writeInProg <- mkReg(False);
   Reg#(Bool)              dataMismatch <- mkReg(False);  
   
   Reg#(Bit#(8)) burstLen <- mkReg(8);
   Reg#(Bit#(DmaAddrSize)) deltaOffset <- mkReg(8*fromInteger(busWidthBytes));

   rule readReq(streamRdCnt > 0);
      streamRdCnt <= streamRdCnt - extend(burstLen);
      streamRdOff <= streamRdOff + deltaOffset;
      //$display("readReq.put handle=%h address=%h, burstlen=%h", streamRdHandle, streamRdOff, burstLen);
      dma_stream_read_server.readReq.put(DmaRequest {handle: streamRdHandle, address: streamRdOff, burstLen: extend(burstLen), tag: truncate(streamRdOff>>5)});
      //indication.readReq(streamRdCnt);
   endrule

   rule writeReq(streamWrCnt > 0 && !writeInProg);
      writeInProg <= True;
      streamWrCnt <= streamWrCnt-extend(burstLen);
      streamWrOff <= streamWrOff + deltaOffset;
      //$display("writeReq.put handle=%h address=%h", streamWrHandle, streamWrOff);
      dma_stream_write_server.writeReq.put(DmaRequest {handle: streamWrHandle, address: streamWrOff, burstLen: extend(burstLen), tag: truncate(streamWrOff>>5)});
      //indication.writeReq(streamWrCnt);
   endrule
   
   rule writeAck(writeInProg);
      writeInProg <= False;
      let tag <- dma_stream_write_server.writeDone.get();
      //$display("writeAck: tag=%d", tag);
      streamAckCnt <= streamAckCnt-extend(burstLen);
      //indication.writeAck(streamAckCnt);
      if(streamAckCnt==extend(burstLen))
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
   
   method Action startCopy(Bit#(32) wrHandle, Bit#(32) rdHandle, Bit#(32) numWords) if (streamRdCnt == 0 && streamWrCnt == 0);
      //$display("startCopy wrHandle=%h rdHandle=%h numWords=%d", wrHandle, rdHandle, numWords);
      streamRdOff <= 0;
      streamWrOff <= 0;

      streamWrHandle <= wrHandle;
      streamRdHandle <= rdHandle;
      streamRdCnt <= numWords>>1;
      streamWrCnt <= numWords>>1;
      streamAckCnt <= numWords>>1;
      indication.started(numWords);
   endmethod

   method Action readWord();
      dma_word_read_server.readReq.put(DmaRequest {handle: streamWrHandle, address: 0, burstLen: 1, tag: 1});
   endmethod

   method Action getStateDbg();
      indication.reportStateDbg(srcGen, streamRdCnt, streamWrCnt, writeInProg ? 32'd1 : 32'd0, dataMismatch  ? 32'd1 : 32'd0);
   endmethod

endmodule
