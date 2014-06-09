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

import FIFO::*;
import FIFOF::*;
import GetPut::*;
import ClientServer::*;

import AxiMasterSlave::*;
import MemTypes::*;
import MemwriteEngine::*;
import Pipe::*;

interface MemwriteRequest;
   method Action startWrite(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
   method Action getStateDbg();   
endinterface

interface Memwrite;
   interface MemwriteRequest request;
   interface ObjectWriteClient#(64) dmaClient;
endinterface

interface MemwriteIndication;
   method Action started(Bit#(32) numWords);
   method Action reportStateDbg(Bit#(32) wrCnt, Bit#(32) srcGen);
   method Action writeDone(Bit#(32) v);
endinterface

module  mkMemwrite#(MemwriteIndication indication) (Memwrite);

   Reg#(ObjectPointer)     pointer <- mkReg(0);
   Reg#(Bit#(32))         numWords <- mkReg(0);
   Reg#(Bit#(32))         burstLen <- mkReg(0);
   Reg#(Bit#(32))          iterCnt <- mkReg(0);

   Reg#(Bit#(32))           srcGen <- mkReg(0);
   MemwriteEngine#(64,1)        we <- mkMemwriteEngine;

   rule start (iterCnt > 0);
      iterCnt <= iterCnt-1;
      we.writeServers[0].request.put(MemengineCmd{pointer:pointer, base:0, len:numWords*4, burstLen:truncate(burstLen*4)});
   endrule
   
   rule finish;
      let rv <- we.writeServers[0].response.get;
      if (iterCnt == 0)
	 indication.writeDone(0);
   endrule
   
   rule src (numWords > 0);
      if (srcGen+2 == numWords)
	 srcGen <= 0;
      else
	 srcGen <= srcGen+2;
      we.dataPipes[0].enq({srcGen+1,srcGen});
   endrule

   interface ObjectWriteClient dmaClient = we.dmaClient;
   interface MemwriteRequest request;
       method Action startWrite(Bit#(32) wp, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
	  $display("startWrite pointer=%d numWords=%h burstLen=%d iterCnt=%d", pointer, nw, bl, ic);
	  indication.started(nw);
	  pointer <= wp;
	  numWords <= nw;
	  burstLen <= bl;
	  iterCnt <= ic;
	  srcGen <= 0;
       endmethod
       method Action getStateDbg();
	  indication.reportStateDbg(iterCnt, srcGen);
       endmethod
   endinterface
endmodule