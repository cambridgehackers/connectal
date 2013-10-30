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

interface CoreRequest;
   method Action startWrite(Bit#(32) numWords);
   method Action getStateDbg();   
endinterface

interface CoreIndication;
   method Action started(Bit#(32) numWords);
   method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) srcGen);
   method Action writeReq(Bit#(32) v);
   method Action writeDone(Bit#(32) v);
endinterface

interface MemwriteRequest;
   interface Axi3Client#(40,64,8,12) m_axi;
   interface CoreRequest coreRequest;
   interface DMARequest dmaRequest;
endinterface

interface MemwriteIndication;
   interface CoreIndication coreIndication;
   interface DMAIndication dmaIndication;
endinterface

module mkMemwriteRequest#(MemwriteIndication indication)(MemwriteRequest);

   AxiDMA                 dma <- mkAxiDMA(indication.dmaIndication);
   Reg#(Bit#(32)) streamWrCnt <- mkReg(0);
   Reg#(Bit#(32))      srcGen <- mkReg(0);

   // dma write channel 0 is reserved for memwrite write path
   WriteChan dma_stream_write_chan = dma.write.writeChannels[0];

   rule produce;
      dma_stream_write_chan.writeData.put({srcGen+1,srcGen});
      srcGen <= srcGen+2;
   endrule
   
   rule writeReq(streamWrCnt > 0);
      streamWrCnt <= streamWrCnt-16;
      dma_stream_write_chan.writeReq.put(?);
      if (streamWrCnt[5:0] == 6'b0)
	 indication.coreIndication.writeReq(streamWrCnt);
      if (streamWrCnt == 16)
	 indication.coreIndication.writeDone(srcGen);
   endrule

   interface CoreRequest coreRequest;
      method Action startWrite(Bit#(32) numWords) if (streamWrCnt == 0);
	 streamWrCnt <= numWords;
	 indication.coreIndication.started(numWords);
      endmethod
      
      method Action getStateDbg();
	 indication.coreIndication.reportStateDbg(streamWrCnt, srcGen);
      endmethod
   endinterface
   interface Axi3Client m_axi = dma.m_axi;
   interface DMARequest dmaRequest = dma.request;
endmodule