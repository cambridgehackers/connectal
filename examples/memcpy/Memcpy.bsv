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
import BRAMFIFO::*;
import GetPut::*;

import AxiClientServer::*;
import PortalMemory::*;
import PortalRMemory::*;
import AxiRDMA::*;
import BsimRDMA::*;
import BlueScope::*;

interface MemcpyRequest;
   method Action startCopy(Bit#(32) wrHandle, Bit#(32) rdHandle, Bit#(32) numWords);
   method Action readWord();
   method Action getStateDbg();   
endinterface

interface MemcpyIndication;
   method Action started(Bit#(32) numWords);
   method Action readWordResult(Bit#(64) v);
   method Action done(Bit#(32) dataMismatch);
   method Action rData(Bit#(64) v);
   method Action readReq(Bit#(32) v);
   method Action writeReq(Bit#(32) v);
   method Action writeAck(Bit#(32) v);
   method Action reportStateDbg(Bit#(32) srcGen, Bit#(32) streamRdCnt, Bit#(32) streamWrCnt, Bit#(32) writeInProg, Bit#(32) dataMismatch);
endinterface

module mkMemcpyRequest#(MemcpyIndication indication,
			DMAReadServer#(64) dma_stream_read_server,
			DMAWriteServer#(64) dma_stream_write_server,
			DMAReadServer#(64) dma_word_read_server,
			BlueScope bs)(MemcpyRequest);

   Reg#(Bit#(32))      srcGen <- mkReg(0);
   Reg#(Bit#(32)) streamRdCnt <- mkReg(0);
   Reg#(Bit#(32)) streamWrCnt <- mkReg(0);
   Reg#(Bit#(40)) streamRdOff <- mkReg(0);
   Reg#(Bit#(40)) streamWrOff <- mkReg(0);
   Reg#(DmaMemHandle)    streamRdHandle <- mkReg(0);
   Reg#(DmaMemHandle)    streamWrHandle <- mkReg(0);
   Reg#(DmaMemHandle) bluescopeWrHandle <- mkReg(0);
   Reg#(Bool)               writeInProg <- mkReg(False);
   Reg#(Bool)              dataMismatch <- mkReg(False);  
   
   rule readReq(streamRdCnt > 0);
      streamRdCnt <= streamRdCnt - 1;
      streamRdOff <= streamRdOff + 1;
      // $display("readReq.put handle=%h address=%h", streamRdHandle, streamRdOff);
      dma_stream_read_server.readReq.put(DMAAddressRequest {handle: streamRdHandle, address: streamRdOff, burstLen: 1, tag: truncate(streamRdOff)});
      indication.readReq(streamRdCnt);
   endrule

   rule writeReq(streamWrCnt > 0 && !writeInProg);
      writeInProg <= True;
      streamWrOff <= streamWrOff + 1;
      //$display("writeReq.put handle=%h address=%h", streamWrHandle, streamWrOff);
      dma_stream_write_server.writeReq.put(DMAAddressRequest {handle: streamWrHandle, address: streamWrOff, burstLen: 1, tag: truncate(streamWrOff)});
      indication.writeReq(streamWrCnt);
   endrule
   
   rule writeAck(writeInProg);
      writeInProg <= False;
      let tag <- dma_stream_write_server.writeDone.get();
      //$display("writeAck: tag=%d", tag);
      streamWrCnt <= streamWrCnt-1;
      indication.writeAck(streamWrCnt);
      if(streamWrCnt==1)
   	 indication.done(dataMismatch ? 32'd1 : 32'd0);
   endrule

   rule loopback;
      let tagdata <- dma_stream_read_server.readData.get();
      let v = tagdata.data;
      let misMatch0 = v[31:0] != srcGen;
      let misMatch1 = v[63:32] != srcGen+1;
      dataMismatch <= dataMismatch || misMatch0 || misMatch1;
      dma_stream_write_server.writeData.put(tagdata);
      bs.dataIn(v,v);
      srcGen <= srcGen+2;
      //$display("loopback %h", tagdata.data);
      // indication.rData(v);
   endrule
   
   rule readWordResp;
      let tagdata <- dma_word_read_server.readData.get;
      indication.readWordResult(tagdata.data);
   endrule
   
   method Action startCopy(Bit#(32) wrHandle, Bit#(32) rdHandle, Bit#(32) numWords) if (streamRdCnt == 0 && streamWrCnt == 0);
      //$display("startCopy wrHandle=%h rdHandle=%h numWords=%d", wrHandle, rdHandle, numWords);
      streamWrHandle <= wrHandle;
      streamRdHandle <= rdHandle;
      streamRdCnt <= numWords>>1;
      streamWrCnt <= numWords>>1;
      indication.started(numWords);
   endmethod

   method Action readWord();
      dma_word_read_server.readReq.put(DMAAddressRequest {handle: streamWrHandle, address: 0, burstLen: 1, tag: 1});
   endmethod

   method Action getStateDbg();
      indication.reportStateDbg(srcGen, streamRdCnt, streamWrCnt, writeInProg ? 32'd1 : 32'd0, dataMismatch  ? 32'd1 : 32'd0);
   endmethod

endmodule