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
import Pipe::*;
import ConnectalMemTypes::*;
import MemReadEngine::*;
import ConnectalConfig::*;

interface ReadTestRequest;
   method Action startRead(Bit#(32) pointer, Bit#(32) numBytes, Bit#(32) burstLen, Bit#(32) iterCnt);
   method Action getStateDbg();   
endinterface

interface ReadTest#(numeric type nClients);
   interface ReadTestRequest request;
   interface Vector#(nClients,MemReadClient#(DataBusWidth)) dmaClients;
endinterface

interface ReadTestIndication;
   method Action started(Bit#(32) numBytes);
   method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) mismatchCount);
   method Action readDone(Bit#(32) mismatchCount);
endinterface

module mkReadTest#(ReadTestIndication indication) (ReadTest#(4));

   Reg#(SGLId)     pointer <- mkReg(0);
   Reg#(Bit#(32))         numBytes <- mkReg(0);
   Reg#(Bit#(BurstLenSize)) burstLenBytes <- mkReg(0);
   Reg#(Bit#(32))          itersToStart <- mkReg(0);
   Reg#(Bit#(32))        startBase <- mkReg(0);
   Reg#(Bit#(3))          startPtr <- mkReg(0);
   Reg#(Bit#(3))         finishPtr <- mkReg(0);
   Reg#(Bit#(32))    mismatchAccum <- mkReg(0);
   Vector#(4,MemReadEngine#(DataBusWidth,DataBusWidth,1,1))      res <- replicateM(mkMemReadEngine);
   FIFO#(void)           startFifo <- mkFIFO;
   
   Vector#(4,Reg#(Bit#(32)))        srcGens <- replicateM(mkReg(0));
   Vector#(4,Reg#(Bit#(32))) mismatchCounts <- replicateM(mkReg(0));
   Vector#(4,FIFO#(void)) doneFifo <- replicateM(mkFIFO);
   
   Stmt startStmt = seq
		       startBase <= 0;
		       for(startPtr <= 0; startPtr < 4; startPtr <= startPtr+1)
			  (action
			      let cmd = MemengineCmd{sglId:pointer, base:extend(startBase), len:numBytes, burstLen:truncate(burstLenBytes), tag:0};
			      res[startPtr].readServers[0].request.put(cmd);
			      startBase <= startBase+numBytes;
			      //$display("start:%d %h %d %h (%d)", startPtr, startBase, numBytes, burstLenBytes*4, itersToStart);
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
   
   rule start (itersToStart > 0);
      startFifo.deq;
      startFSM.start;
      itersToStart <= itersToStart-1;
   endrule
   
   rule finish;
      for(Integer i = 0; i < 4; i=i+1)
         doneFifo[i].deq;
      //$display("finish: %d (%d)", i, itersToStart);
      if (itersToStart == 0)
	 finishFSM.start;
      else
	 startFifo.enq(?);
   endrule
   
   for(Integer i = 0; i < 4; i=i+1)
      rule check;
	 let v <- toGet(res[i].readServers[0].data).get;
	 let expectedV = {srcGens[i]+3,srcGens[i]+2,srcGens[i]+1,srcGens[i]};
	 let misMatch = v.data != expectedV;
	 mismatchCounts[i] <= mismatchCounts[i] + (misMatch ? 1 : 0);
	 if (srcGens[i]+4 == fromInteger(i+1)*(numBytes>>2)) begin
	    //$display("check %d %d", i, srcGens[i]+1);
	    srcGens[i] <= fromInteger(i)*(numBytes>>2);
	 end
	 else
	    srcGens[i] <= srcGens[i]+4;
         if (v.last)
            doneFifo[i].enq(?);
      endrule
   
   function MemReadClient#(DataBusWidth) dc(MemReadEngine#(DataBusWidth,DataBusWidth,1,1) re) = re.dmaClient;
   interface dmaClients = map(dc,res);
   interface ReadTestRequest request;
      method Action startRead(Bit#(32) rp, Bit#(32) nb, Bit#(32) bl, Bit#(32) ic);
	 //$display("startRead rdPointer=%d numBytes=%h burstLenBytes=%d itersToStart=%d", rp, nb, bl, ic);
	 indication.started(nb);
	 pointer <= rp;
	 numBytes  <= nb;
	 burstLenBytes  <= truncate(bl);
	 itersToStart <= ic;
	 for(Integer i = 0; i < 4; i=i+1) begin
	    mismatchCounts[i] <= 0;
	    srcGens[i] <= fromInteger(i)*(nb>>2);
	 end
	 startFifo.enq(?);
      endmethod
      method Action getStateDbg();
	 indication.reportStateDbg(itersToStart, mismatchCounts[0]);
      endmethod
   endinterface
endmodule
