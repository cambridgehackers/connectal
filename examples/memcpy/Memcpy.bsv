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
   method Action startCopy(Bit#(32) numWords);
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
			ReadChan#(Bit#(64)) dma_stream_read_chan,
			WriteChan#(Bit#(64)) dma_stream_write_chan,
			ReadChan#(Bit#(64)) dma_word_read_chan,
			BlueScopeInternal bsi)(MemcpyRequest);

   Reg#(Bit#(32))      srcGen <- mkReg(0);
   Reg#(Bit#(32)) streamRdCnt <- mkReg(0);
   Reg#(Bit#(32)) streamWrCnt <- mkReg(0);
   Reg#(Bit#(40)) streamRdOff <- mkReg(0);
   Reg#(Bit#(40)) streamWrOff <- mkReg(0);
   Reg#(Bool)     writeInProg <- mkReg(False);
   Reg#(Bool)    dataMismatch <- mkReg(False);  
   
   rule readReq(streamRdCnt > 0);
      streamRdCnt <= streamRdCnt - 1;
      streamRdOff <= streamRdOff + 1;
      dma_stream_read_chan.readReq.put(streamRdOff);
      indication.readReq(streamRdCnt);
   endrule

   rule writeReq(streamWrCnt > 0 && !writeInProg);
      writeInProg <= True;
      streamWrOff <= streamWrOff + 1;
      dma_stream_write_chan.writeReq.put(streamWrOff);
      indication.writeReq(streamWrCnt);
   endrule
   
   rule writeAck(writeInProg);
      writeInProg <= False;
      dma_stream_write_chan.writeDone.get;
      streamWrCnt <= streamWrCnt-1;
      indication.writeAck(streamWrCnt);
      if(streamWrCnt==1)
   	 indication.done(dataMismatch ? 32'd1 : 32'd0);
   endrule

   rule loopback;
      let v <- dma_stream_read_chan.readData.get;
      let misMatch0 = v[31:0] != srcGen;
      let misMatch1 = v[63:32] != srcGen+1;
      dataMismatch <= dataMismatch || misMatch0 || misMatch1;
      dma_stream_write_chan.writeData.put(v);
      bsi.dataIn(v,v);
      srcGen <= srcGen+2;
      // $display("%h", v);
      // indication.rData(v);
   endrule
   
   rule readWordResp;
      let v <- dma_word_read_chan.readData.get;
      indication.readWordResult(v);
   endrule
   
   method Action startCopy(Bit#(32) numWords) if (streamRdCnt == 0 && streamWrCnt == 0);
      streamRdCnt <= numWords;
      streamWrCnt <= numWords;
      indication.started(numWords);
   endmethod
   
   method Action readWord();
      dma_word_read_chan.readReq.put(0);
   endmethod
	 
   method Action getStateDbg();
      indication.reportStateDbg(srcGen, streamRdCnt, streamWrCnt, writeInProg ? 32'd1 : 32'd0, dataMismatch  ? 32'd1 : 32'd0);
   endmethod

endmodule