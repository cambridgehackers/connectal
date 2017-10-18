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
import Vector::*;
import ClientServer::*;
import GetPut::*;
import ConnectalMemTypes::*;
import MemWriteEngine::*;
import Pipe::*;
import Arith::*;
import ConnectalMemUtils::*;
import ConnectalConfig::*;
import StmtFSM ::*;

interface MemwriteRequest;
   method Action startWrite(Bit#(32) pointer, Bit#(32) offset, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
   method Action getStateDbg();   
endinterface

interface Memwrite#(numeric type nClients);
   interface MemwriteRequest request;
   interface Vector#(nClients,MemWriteClient#(64)) dmaClients;
endinterface

interface MemwriteIndication;
   method Action started(Bit#(32) numWords);
   method Action reportStateDbg(Bit#(32) wrCnt, Bit#(32) srcGen);
   method Action writeDone(Bit#(32) v);
endinterface

module  mkMemwrite#(MemwriteIndication indication) (Memwrite#(4));

   Reg#(SGLId)     pointer <- mkReg(0);
   Reg#(Bit#(32))         numWords <- mkReg(0);
   Reg#(Bit#(32))         burstLen <- mkReg(0);
   Reg#(Bit#(32))          iterCnt <- mkReg(0);
   Reg#(Bit#(32))        startBase <- mkReg(0);
   Reg#(Bit#(3))          startPtr <- mkReg(0);
   Reg#(Bit#(3))         finishPtr <- mkReg(0);
   FIFO#(void)           startFifo <- mkFIFO;

   Vector#(4,Reg#(Bit#(32)))      srcGens <- replicateM(mkReg(0));
   Vector#(4,MemWriteEngine#(64,64,2,1))   wes <- replicateM(mkMemWriteEngine);

   Stmt startStmt = seq
		       startBase <= 0;
		       for(startPtr <= 0; startPtr < 4; startPtr <= startPtr+1)
			  (action
			      $display("start:%d %h %d %h (%d)", startPtr, startBase, numWords, burstLen*4, iterCnt);
			      wes[startPtr].writeServers[0].request.put(MemengineCmd{sglId:pointer, base:extend(startBase), len:numWords, burstLen:truncate(burstLen*4), tag:0});
			      startBase <= startBase+numWords;
			   endaction);
		    endseq;
   FSM startFSM <- mkFSM(startStmt);

   rule start (iterCnt > 0);
      startFifo.deq;
      startFSM.start;
      iterCnt <= iterCnt-1;
   endrule
   
   rule finish;
      for(Integer i = 0; i < 4; i=i+1) begin
	 $display("finish: %d (%d)", i, iterCnt);
	 let rv <- wes[i].writeServers[0].done.get;
      end
      if (iterCnt == 0)
	 indication.writeDone(0);
      else
	 startFifo.enq(?);
   endrule
   
   for(Integer i = 0; i < 4; i=i+1)
      rule src;
	 wes[i].writeServers[0].data.enq({srcGens[i]+1,srcGens[i]});
	 if (srcGens[i]+2 == fromInteger(i+1)*(numWords>>2)) begin
	    //$display("src %d %d", i, srcGens[i]+1);
	    srcGens[i] <= fromInteger(i)*(numWords>>2);
	 end
	 else
	    srcGens[i] <= srcGens[i]+2;
      endrule

   function MemWriteClient#(64) dc(MemWriteEngine#(64,64,2,1) we) = we.dmaClient;
   interface dmaClients = map(dc,wes);
   interface MemwriteRequest request;
      method Action startWrite(Bit#(32) wp, Bit#(32) ofs, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
	  $display("startWrite pointer=%d numWords=%h burstLen=%d iterCnt=%d", pointer, nw, bl, ic);
	  indication.started(nw);
	  pointer <= wp;
	  numWords <= nw;
	  burstLen <= bl;
	  iterCnt <= ic;
	  for(Integer i = 0; i < 4; i=i+1)
	     srcGens[i] <= fromInteger(i)*(nw>>2);
	  startFifo.enq(?);
       endmethod
       method Action getStateDbg();
	  indication.reportStateDbg(iterCnt, srcGens[0]);
       endmethod
   endinterface
endmodule
