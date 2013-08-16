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

interface Memcpy;
   method Action startDMA(Bit#(32) numWords);
   method Action readWord();
   method Action configDmaWriteChan(Bit#(32) chanId, Bit#(32) pa, Bit#(32) bsz);
   method Action configDmaReadChan(Bit#(32) chanId, Bit#(32) pa, Bit#(32) bsz);
   interface Axi3Client#(64,8,6) m_axi;
endinterface

interface MemcpyIndications;
    method Action started(Bit#(32) numWords);
    method Action readWordResult(Bit#(64) v);
    method Action done(Bit#(32) dataMismatch);
    method Action rData(Bit#(64) v);
    method Action readReq(Bit#(32) v);
    method Action writeReq(Bit#(32) v);
    method Action writeAck(Bit#(32) v);
endinterface

module mkMemcpy#(MemcpyIndications indications)(Memcpy);

   AxiDMA dma <- mkAxiDMA;
   Reg#(Bit#(32))      srcGen <- mkReg(0);
   Reg#(Bit#(32)) streamRdCnt <- mkReg(0);
   Reg#(Bit#(32)) streamWrCnt <- mkReg(0);
   Reg#(Bool)     writeInProg <- mkReg(False);
   Reg#(Bool)    dataMismatch <- mkReg(False);  

   Get#(Bit#(64)) dma_stream_read_data = dma.read.readData[0];
   Put#(void)     dma_stream_read_req  = dma.read.readReq[0];

   Put#(Bit#(64)) dma_stream_write_data = dma.write.writeData[0];
   Put#(void)     dma_stream_write_req  = dma.write.writeReq[0];
   Get#(void)     dma_stream_write_done = dma.write.writeDone[0];
   
   Get#(Bit#(64)) dma_word_read_data = dma.read.readData[1];
   Put#(void)     dma_word_read_req = dma.read.readReq[1];
   
   rule readReq(streamRdCnt > 0);
      streamRdCnt <= streamRdCnt-16;
      dma_stream_read_req.put(?);
      indications.readReq(streamRdCnt);
   endrule

   rule writeReq(streamWrCnt > 0 && !writeInProg);
      writeInProg <= True;
      dma_stream_write_req.put(?);
      indications.writeReq(streamWrCnt);
   endrule
   
   rule writeAck(writeInProg);
      writeInProg <= False;
      dma_stream_write_done.get;
      streamWrCnt <= streamWrCnt-16;
      indications.writeAck(streamWrCnt);
      if(streamWrCnt==16)
   	 indications.done(dataMismatch ? 32'd1 : 32'd0);
   endrule
   
   rule loopback;
      let v <- dma_stream_read_data.get;
      let misMatch0 = v[31:0] != srcGen;
      let misMatch1 = v[63:32] != srcGen+1;
      dataMismatch <= dataMismatch || misMatch0 || misMatch1;
      dma_stream_write_data.put(v);
      indications.rData(v);
   endrule
   
   rule readWordResp;
      let v <- dma_word_read_data.get;
      indications.readWordResult(v);
   endrule

   method Action startDMA(Bit#(32) numWords) if (streamRdCnt == 0 && streamWrCnt == 0);
      streamRdCnt <= numWords;
      streamWrCnt <= numWords;
      indications.started(numWords);
   endmethod
   
   method Action readWord();
      dma_word_read_req.put(?);
   endmethod
   
   method Action configDmaWriteChan(Bit#(32) chanId, Bit#(32) pa, Bit#(32) bsz);
      dma.write.configChan(truncate(chanId), pa, truncate((bsz>>1)-1));
   endmethod

   method Action configDmaReadChan(Bit#(32) chanId, Bit#(32) pa, Bit#(32) bsz);
      dma.read.configChan(truncate(chanId), pa, truncate((bsz>>1)-1));
   endmethod
   
   interface Axi3Client m_axi = dma.m_axi;
endmodule