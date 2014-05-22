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
import GetPut::*;

import Dma::*;
import MemreadEngine::*;

typedef 32 NumReadClients;

interface MemreadRequest;
   method Action startRead(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
endinterface

interface Memread;
   interface MemreadRequest request;
   interface Vector#(NumReadClients,ObjectReadClient#(64)) dmaClients;
endinterface

interface MemreadIndication;
   method Action started(Bit#(32) numWords);
   method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) mismatchCount);
   method Action readDone(Bit#(32) mismatchCount);
endinterface

module mkMemread#(MemreadIndication indication) (Memread);

   Reg#(ObjectPointer)   pointer <- mkReg(0);
   Reg#(Bit#(ObjectOffsetSize)) startBase <- mkReg(0);
   Reg#(Bit#(32))       numWords <- mkReg(0);
   Reg#(Bit#(32))       burstLen <- mkReg(0);
   Reg#(Bit#(32))       sIterCnt <- mkReg(0);
   Reg#(Bit#(32))       fIterCnt <- mkReg(0);
   Reg#(Bit#(32))       startPtr <- mkReg(0);
   Reg#(Bit#(32))      finishPtr <- mkReg(0);
   Reg#(Bit#(32))    mismatchCnt <- mkReg(0);
   
   Vector#(NumReadClients, Reg#(Bit#(32)))        srcGens <- replicateM(mkReg(0));
   Vector#(NumReadClients, Reg#(Bit#(32))) mismatchCounts <- replicateM(mkReg(0));
   Vector#(NumReadClients, FIFOF#(Bit#(64)))    readFifos <- replicateM(mkFIFOF);
   Vector#(NumReadClients, MemreadEngine#(64))        res <- mapM(uncurry(mkMemreadEngine), zip(replicate(1), readFifos));
   
   Bit#(ObjectOffsetSize) chunk = (extend(numWords)/fromInteger(valueOf(NumReadClients)))*4;
   
   rule start (sIterCnt > 0 && !readFifos[startPtr].notEmpty);
      if (startPtr+1 == fromInteger(valueOf(NumReadClients))) begin
	 sIterCnt <= sIterCnt-1;
	 startPtr <= 0;
	 startBase <= 0;
      end
      else begin
	 startPtr <= startPtr+1;
	 startBase <= startBase+chunk;
      end
      res[startPtr].start(pointer, startBase, truncate(chunk), burstLen*4);
      let srcGen = startPtr * truncate(chunk/4);
      srcGens[startPtr] <= srcGen;
      $display("start %h %d", srcGen, sIterCnt);
   endrule
   
   rule finish;
      if (finishPtr+1 == fromInteger(valueOf(NumReadClients))) begin
	 fIterCnt <= fIterCnt-1;
	 finishPtr <= 0;
	 if (fIterCnt-1==0)
	    indication.readDone(mismatchCnt);	    
      end
      else begin
	 finishPtr <= finishPtr+1;
      end
      $display("finish %d %d", finishPtr, fIterCnt);
      let rv <- res[finishPtr].finish;
      mismatchCnt <= mismatchCnt+mismatchCounts[finishPtr];
      mismatchCounts[finishPtr] <= 0;
   endrule
   
   for(Integer i = 0; i < valueOf(NumReadClients); i=i+1)
      rule check;
	 let v <- toGet(readFifos[i]).get;
	 let expectedV = {srcGens[i]+1,srcGens[i]};
	 let misMatch = v != expectedV;
	 mismatchCounts[i] <= mismatchCounts[i] + (misMatch ? 1 : 0);
	 srcGens[i] <= srcGens[i]+2;
      endrule
   
   function ObjectReadClient#(64) getClient(MemreadEngine#(64) re) = re.dmaClient; 
   interface dmaClients = map(getClient,res);
   interface MemreadRequest request;
      method Action startRead(Bit#(32) rp, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
	 indication.started(nw);
	 pointer <= rp;
	 numWords  <= nw;
	 burstLen  <= bl;
	 sIterCnt <= ic;
	 fIterCnt <= ic;
	 startPtr <= 0;
	 finishPtr <= 0;
      endmethod
   endinterface
endmodule



