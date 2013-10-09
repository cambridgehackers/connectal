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
import AxiDMA::*;
import BlueScope::*;

interface CoreRequest;
   method Action startDMA(Bit#(32) numWords);
   method Action readWord();
   method Action configDmaWriteChan(Bit#(32) chanId, Bit#(32) pa, Bit#(32) numWords);
   method Action configDmaReadChan(Bit#(32) chanId, Bit#(32) pa, Bit#(32) numWords);
   method Action getStateDbg();   
endinterface

interface CoreIndication;
   method Action started(Bit#(32) numWords);
   method Action readWordResult(Bit#(64) v);
   method Action done(Bit#(32) dataMismatch);
   method Action rData(Bit#(64) v);
   method Action readReq(Bit#(32) v);
   method Action writeReq(Bit#(32) v);
   method Action writeAck(Bit#(32) v);
   method Action configResp(Bit#(32) chanId, Bit#(32) pa, Bit#(32) numWords);
   method Action reportStateDbg(Bit#(32) srcGen, Bit#(32) streamRdCnt, Bit#(32) streamWrCnt, Bit#(32) writeInProg, Bit#(32) dataMismatch);
   method Action reportDmaDbg(Bit#(32) x, Bit#(32) y, Bit#(32) z, Bit#(32) w);
endinterface

interface MemcpyRequest;
   interface Axi3Client#(32,64,8,6) m_axi;
   interface CoreRequest coreRequest;
   interface BlueScopeRequest bsRequest;
endinterface

interface MemcpyIndication;
   interface CoreIndication coreIndication;
   interface BlueScopeIndication bsIndication;
endinterface

module mkMemcpyRequest#(MemcpyIndication indication)(MemcpyRequest);

   AxiDMA                 dma <- mkAxiDMA;
   Reg#(Bit#(32))      srcGen <- mkReg(0);
   Reg#(Bit#(32)) streamRdCnt <- mkReg(0);
   Reg#(Bit#(32)) streamWrCnt <- mkReg(0);
   Reg#(Bool)     writeInProg <- mkReg(False);
   Reg#(Bool)    dataMismatch <- mkReg(False);  

   // dma read channel 0 is reserved for memcpy read path
   ReadChan dma_stream_read_chan = dma.read.readChanels[0];

   // dma write channel 0 is reserved for memcpy write path
   WriteChan dma_stream_write_chan = dma.write.writeChannels[0];
   
   // dma read channel 1 is reserved for debug read path
   ReadChan dma_word_read_chan = dma.read.readChanels[1];

   // dma write channel 1 is reserved for Bluescope output
   WriteChan dma_debug_write_chan = dma.write.writeChannels[1];
   BlueScopeInternal bsi <- mkBlueScopeInternal(32, dma_debug_write_chan, indication.bsIndication);
   
   rule readReq(streamRdCnt > 0);
      streamRdCnt <= streamRdCnt-16;
      dma_stream_read_chan.readReq.put(?);
      indication.coreIndication.readReq(streamRdCnt);
      let x = dma.write.dbg;
      //indication.coreIndication.reportDmaDbg(x.x, x.y, x.z, x.w);
   endrule

   rule writeReq(streamWrCnt > 0 && !writeInProg);
      writeInProg <= True;
      dma_stream_write_chan.writeReq.put(?);
      indication.coreIndication.writeReq(streamWrCnt);
   endrule
   
   rule writeAck(writeInProg);
      writeInProg <= False;
      dma_stream_write_chan.writeDone.get;
      streamWrCnt <= streamWrCnt-16;
      //indication.coreIndication.writeAck(streamWrCnt);
      if(streamWrCnt==16)
   	 indication.coreIndication.done(dataMismatch ? 32'd1 : 32'd0);
   endrule

   rule loopback;
      let v <- dma_stream_read_chan.readData.get;
      let misMatch0 = v[31:0] != srcGen;
      let misMatch1 = v[63:32] != srcGen+1;
      dataMismatch <= dataMismatch || misMatch0 || misMatch1;
      dma_stream_write_chan.writeData.put(v);
      bsi.dataIn(v,v);
      indication.coreIndication.rData(v);
   endrule
   
   rule readWordResp;
      let v <- dma_word_read_chan.readData.get;
      indication.coreIndication.readWordResult(v);
   endrule
   
   interface CoreRequest coreRequest;
      method Action startDMA(Bit#(32) numWords) if (streamRdCnt == 0 && streamWrCnt == 0);
	 streamRdCnt <= numWords;
	 streamWrCnt <= numWords;
	 indication.coreIndication.started(numWords);
      endmethod
      
      method Action readWord();
	 dma_word_read_chan.readReq.put(?);
      endmethod
      
      method Action configDmaWriteChan(Bit#(32) chanId, Bit#(32) pa, Bit#(32) numWords);
	 dma.write.configChan(truncate(chanId), pa, truncate((numWords>>1)-1));
	 indication.coreIndication.configResp(chanId, pa, numWords);
      endmethod
   
      method Action configDmaReadChan(Bit#(32) chanId, Bit#(32) pa, Bit#(32) numWords);
	 dma.read.configChan(truncate(chanId), pa, truncate((numWords>>1)-1));
	 indication.coreIndication.configResp(chanId, pa, numWords);
      endmethod
   
      method Action getStateDbg();
	 indication.coreIndication.reportStateDbg(srcGen, streamRdCnt, streamWrCnt, writeInProg ? 32'd1 : 32'd0, dataMismatch  ? 32'd1 : 32'd0);
      endmethod
   endinterface
   interface BlueScopeRequest bsRequest = bsi.requestIfc;
   interface Axi3Client m_axi = dma.m_axi;
endmodule