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
import StmtFSM::*;
import GetPut::*;
import ClientServer::*;

import MemTypes::*;
import MemreadEngine::*;
import Pipe::*;

interface MemreadRequest;
   method Action startRead(Bit#(32) pointer, Bit#(32) offset, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
   method Action getStateDbg();   
endinterface

interface Memread#(numeric type nClients);
   interface MemreadRequest request;
   interface Vector#(nClients,MemReadClient#(64)) dmaClients;
endinterface

interface MemreadIndication;
   method Action started(Bit#(32) numWords);
   method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) mismatchCount);
   method Action readDone(Bit#(32) mismatchCount);
endinterface

module mkMemread#(MemreadIndication indication) (Memread#(4));

   Reg#(SGLId)     pointer <- mkReg(0);
   Reg#(Bit#(32))         numWords <- mkReg(0);
   Reg#(Bit#(32))         burstLen <- mkReg(0);
   Reg#(Bit#(32))          iterCnt <- mkReg(0);
   Reg#(Bit#(32))        startBase <- mkReg(0);
   Reg#(Bit#(3))          startPtr <- mkReg(0);
   Reg#(Bit#(3))         finishPtr <- mkReg(0);
   Reg#(Bit#(32))    mismatchAccum <- mkReg(0);
   FIFO#(void)           startFifo <- mkFIFO;
   
   Vector#(4,Reg#(Bit#(32)))        srcGens <- replicateM(mkReg(0));
   Vector#(4,Reg#(Bit#(32))) mismatchCounts <- replicateM(mkReg(0));
   Vector#(4,MemreadEngine#(64,1))      res <- replicateM(mkMemreadEngine);
   
   Stmt startStmt = seq
		       startBase <= 0;
		       for(startPtr <= 0; startPtr < 4; startPtr <= startPtr+1)
			  (action
			      let cmd = MemengineCmd{sglId:pointer, base:extend(startBase), len:numWords, burstLen:truncate(burstLen*4)};
			      res[startPtr].readServers[0].request.put(cmd);
			      startBase <= startBase+numWords;
			      //$display("start:%d %h %d %h (%d)", startPtr, startBase, numWords, burstLen*4, iterCnt);
			   endaction);
		    endseq;
   FSM startFSM <- mkFSM(startStmt);

   Stmt finishStmt = seq
			mismatchAccum <= 0;
			for(finishPtr <= 0; finishPtr < 4; finishPtr <= finishPtr+1)
			   mismatchAccum <= mismatchAccum + mismatchCounts[finishPtr];
			indication.readDone(mismatchAccum);
			//$display("finishStmt: %h", mismatchAccum);
		    endseq;
   FSM finishFSM <- mkFSM(finishStmt);
   
   rule start (iterCnt > 0);
      startFifo.deq;
      startFSM.start;
      iterCnt <= iterCnt-1;
   endrule
   
   rule finish;
      for(Integer i = 0; i < 4; i=i+1) begin
	 //$display("finish: %d (%d)", i, iterCnt);
	 let rv <- res[i].readServers[0].response.get;
      end
      if (iterCnt == 0)
	 finishFSM.start;
      else
	 startFifo.enq(?);
   endrule
   
   for(Integer i = 0; i < 4; i=i+1)
      rule check;
	 let v <- toGet(res[i].dataPipes[0]).get;
	 let expectedV = {srcGens[i]+1,srcGens[i]};
	 let misMatch = v != expectedV;
	 mismatchCounts[i] <= mismatchCounts[i] + (misMatch ? 1 : 0);
	 if (srcGens[i]+2 == fromInteger(i+1)*(numWords>>2)) begin
	    //$display("check %d %d", i, srcGens[i]+1);
	    srcGens[i] <= fromInteger(i)*(numWords>>2);
	 end
	 else
	    srcGens[i] <= srcGens[i]+2;
      endrule
   
   function MemReadClient#(64) dc(MemreadEngine#(64,1) re) = re.dmaClient;
   interface dmaClients = map(dc,res);
   interface MemreadRequest request;
      method Action startRead(Bit#(32) rp, Bit#(32) off, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
	 //$display("startRead rdPointer=%d numWords=%h burstLen=%d iterCnt=%d", rp, nw, bl, ic);
	 indication.started(nw);
	 pointer <= rp;
	 numWords  <= nw;
	 burstLen  <= bl;
	 iterCnt <= ic;
	 for(Integer i = 0; i < 4; i=i+1) begin
	    mismatchCounts[i] <= 0;
	    srcGens[i] <= fromInteger(i)*(nw>>2);
	 end
	 startFifo.enq(?);
      endmethod
      method Action getStateDbg();
	 indication.reportStateDbg(iterCnt, mismatchCounts[0]);
      endmethod
   endinterface
endmodule


