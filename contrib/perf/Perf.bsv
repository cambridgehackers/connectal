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

import ConnectalMemory::*;
import ConnectalMemTypes::*;

interface PerfRequest;
   method Action startCopy(Bit#(32) wrPointer, Bit#(32) rdPointer, Bit#(32) numWords, Bit#(32) repeatCount);
   method Action readWord();
   method Action getStateDbg();   
endinterface

interface PerfIndication;
   method Action started(Bit#(32) numWords);
   method Action readWordResult(Bit#(32) v);
   method Action done(Bit#(32) dataMismatch);
   method Action rData(Bit#(64) v);
   method Action readReq(Bit#(32) v);
   method Action writeReq(Bit#(32) v);
   method Action writeAck(Bit#(32) v);
   method Action reportStateDbg(Bit#(32) srcGen, Bit#(32) streamRdCnt, Bit#(32) streamWrCnt, Bit#(32) writeInProg, Bit#(32) dataMismatch);
endinterface

module mkPerfRequest#(PerfIndication indication,
			MemReadServer#(busWidth) dma_stream_read_server,
			MemWriteServer#(busWidth) dma_stream_write_server,
			MemReadServer#(busWidth) dma_word_read_server)
   (PerfRequest)
   provisos (Div#(busWidth,8,busWidthBytes),
	     Add#(a__,32,busWidth));

   let busWidthBytes = valueOf(busWidthBytes);
   let busWidthWords = busWidthBytes/4;

   Reg#(Bit#(32))      srcGen <- mkReg(0);
   Reg#(Bit#(32)) byteCnt <- mkReg(0);
   Reg#(Bit#(32)) streamRdCnt <- mkReg(0);
   Reg#(Bit#(32)) streamWrCnt <- mkReg(0);
   Reg#(Bit#(32)) streamAckCnt <- mkReg(0);
   Reg#(Bit#(32)) repeatCnt <- mkReg(0);
   Reg#(Bit#(MemOffsetSize)) streamRdOff <- mkReg(0);
   Reg#(Bit#(MemOffsetSize)) streamWrOff <- mkReg(0);
   Reg#(SGLId)    streamRdPointer <- mkReg(0);
   Reg#(SGLId)    streamWrPointer <- mkReg(0);
   Reg#(Bool)               writeInProg <- mkReg(False);
   Reg#(Bool)               iterInProg <- mkReg(False);
   Reg#(Bool)              dataMismatch <- mkReg(False);  
   
   Reg#(Bit#(8)) burstLen <- mkReg(8*fromInteger(busWidthBytes));
   Reg#(Bit#(MemOffsetSize)) deltaOffset <- mkReg(8*fromInteger(busWidthBytes));

   rule readReq(streamRdCnt > 0);
      streamRdCnt <= streamRdCnt - extend(burstLen);
      streamRdOff <= streamRdOff + deltaOffset;
      //$display("readReq.put pointer=%h address=%h, burstlen=%h", streamRdPointer, streamRdOff, burstLen);
      dma_stream_read_server.readReq.put(MemRequest {sglId: streamRdPointer, offset: streamRdOff, burstLen: extend(burstLen), tag: truncate(streamRdOff>>5)});
      //indication.readReq(streamRdCnt);
   endrule

   rule writeReq(streamWrCnt > 0 && !writeInProg);
      writeInProg <= True;
      streamWrCnt <= streamWrCnt-extend(burstLen);
      streamWrOff <= streamWrOff + deltaOffset;
      //$display("writeReq.put pointer=%h address=%h", streamWrPointer, streamWrOff);
      dma_stream_write_server.writeReq.put(MemRequest {sglId: streamWrPointer, offset: streamWrOff, burstLen: extend(burstLen), tag: truncate(streamWrOff>>5)});
      //indication.writeReq(streamWrCnt);
   endrule
   
   rule writeAck(writeInProg);
      writeInProg <= False;
      let tag <- dma_stream_write_server.writeDone.get();
      //$display("writeAck: tag=%d", tag);
      streamAckCnt <= streamAckCnt-extend(burstLen);
      //indication.writeAck(streamAckCnt);
      if(streamAckCnt==extend(burstLen)) begin
	 if (repeatCnt == 0) indication.done(0);
	 iterInProg <= False;
	 end
   endrule

   rule loopback;
      let tagdata <- dma_stream_read_server.readData.get();
      let v = tagdata.data;
      Bool mismatch = False;
      //for (Integer i = 0; i < busWidthWords; i = i+1)
	// mismatch = mismatch || (v[31+i*32:i*32] != (srcGen + fromInteger(i)));
      //dataMismatch <= dataMismatch || mismatch;
      dma_stream_write_server.writeData.put(tagdata);
      srcGen <= srcGen+fromInteger(busWidthWords);
      //$display("loopback %h", tagdata.data);
      // indication.rData(v);
   endrule
   
   rule readWordResp;
      let tagdata <- dma_word_read_server.readData.get;
      indication.readWordResult(truncate(tagdata.data));
   endrule
   
   rule startIteration((iterInProg == False) && (repeatCnt > 0));
      streamRdOff <= 0;
      streamWrOff <= 0;
      streamRdCnt <= byteCnt;
      streamWrCnt <= byteCnt;
      streamAckCnt <= byteCnt;
      iterInProg <= True;
      repeatCnt <= repeatCnt - 1;
   endrule
   
   method Action startCopy(Bit#(32) wrPointer, Bit#(32) rdPointer, Bit#(32) numWords, Bit#(32) repeatCount) if (streamRdCnt == 0 && streamWrCnt == 0);
      //$display("startCopy wrPointer=%h rdPointer=%h numWords=%d", wrPointer, rdPointer, numWords);
      streamWrPointer <= wrPointer;
      streamRdPointer <= rdPointer;
      byteCnt <= numWords << 2;
      repeatCnt <= repeatCount;
      indication.started(numWords);
   endmethod

   method Action readWord();
      dma_word_read_server.readReq.put(MemRequest {sglId: streamWrPointer, offset: 0, burstLen: fromInteger(busWidthBytes), tag: 1});
   endmethod

   method Action getStateDbg();
      indication.reportStateDbg(srcGen, streamRdCnt, streamWrCnt, writeInProg ? 32'd1 : 32'd0, dataMismatch  ? 32'd1 : 32'd0);
   endmethod

endmodule
