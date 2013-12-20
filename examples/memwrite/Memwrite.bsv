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

interface MemwriteRequest;
   method Action startWrite(Bit#(32) numWords);
   method Action getStateDbg();   
endinterface

interface MemwriteIndication;
   method Action started(Bit#(32) numWords);
   method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) srcGen);
   method Action writeReq(Bit#(32) v);
   method Action writeDone(Bit#(32) v);
endinterface


module mkMemwriteRequest#(MemwriteIndication indication,
			  WriteChan#(Bit#(64)) dma_stream_write_chan) (MemwriteRequest);

   Reg#(Bit#(32)) streamWrCnt <- mkReg(0);
   Reg#(Bit#(40)) streamWrOff <- mkReg(0);
   Reg#(Bit#(32))      srcGen <- mkReg(0);

   rule resp;
      dma_stream_write_chan.writeDone.get;
   endrule
   
   rule produce;
      dma_stream_write_chan.writeData.put({srcGen+1,srcGen});
      srcGen <= srcGen+2;
   endrule
   
   rule writeReq(streamWrCnt > 0);
      streamWrCnt <= streamWrCnt-1;
      dma_stream_write_chan.writeReq.put(streamWrOff);
      streamWrOff <= streamWrOff + 1;
      indication.writeReq(streamWrCnt);
      if (streamWrCnt == 1)
	 indication.writeDone(srcGen);
   endrule

   method Action startWrite(Bit#(32) numWords) if (streamWrCnt == 0);
      streamWrCnt <= numWords;
      indication.started(numWords);
   endmethod
   
   method Action getStateDbg();
      indication.reportStateDbg(streamWrCnt, srcGen);
   endmethod
endmodule