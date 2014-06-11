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
import ClientServer::*;

import Pipe::*;
import MemTypes::*;
import MemreadEngine::*;
import Pipe::*;

typedef 32 NumEngineServers;

interface MemreadRequest;
   method Action startRead(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
   method Action getStateDbg();   
endinterface

interface Memread;
   interface MemreadRequest request;
   interface ObjectReadClient#(64) dmaClient;
endinterface

interface MemreadIndication;
   method Action started(Bit#(32) numWords);
   method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) mismatchCount);
   method Action readDone(Bit#(32) mismatchCount);
endinterface

module [Module] mkMemread#(MemreadIndication indication) (Memread);

   Reg#(ObjectPointer)   pointer <- mkReg(0);
   Reg#(Bit#(32))       numWords <- mkReg(0);
   Reg#(Bit#(32))       burstLen <- mkReg(0);
   Reg#(Bit#(32))    mismatchCnt <- mkReg(0);
   FIFO#(void)                cf <- mkSizedFIFO(1);
   
   Reg#(Bit#(32))                                   iterCnt <- mkReg(0);
   Vector#(NumEngineServers, Reg#(Bit#(32)))       iterCnts <- replicateM(mkReg(0));
   Vector#(NumEngineServers, Reg#(Bit#(32)))        srcGens <- replicateM(mkReg(0));
   Vector#(NumEngineServers, Reg#(Bit#(32))) mismatchCounts <- replicateM(mkReg(0));
   MemreadEngineV#(64,2,NumEngineServers)                re <- mkMemreadEngineV;
   Vector#(NumEngineServers, FIFOF#(Bit#(32))) mismatchFifos <- replicateM(mkFIFOF);
   Bit#(ObjectOffsetSize) chunk = (extend(numWords)/fromInteger(valueOf(NumEngineServers)))*4;
   
   
   for(Integer i = 0; i < valueOf(NumEngineServers); i=i+1) begin
      rule start (iterCnts[i] > 0);
	 re.readServers[i].request.put(MemengineCmd{pointer:pointer, base:fromInteger(i)*chunk, len:truncate(chunk), burstLen:truncate(burstLen*4)});
	 $display("start %d, %d", i, iterCnts[i]);
	 iterCnts[i] <= iterCnts[i]-1;
      endrule
      rule finish;
	 $display("finish %d", i);
	 let rv <- re.readServers[i].response.get;
	 // need to pipeline this also
	 //mismatchCnt <= mismatchCnt+mismatchCounts[i];
	 mismatchCounts[i] <= 0;
	 mismatchFifos[i].enq(mismatchCounts[i]);
      endrule
      rule check;
	 let v <- toGet(re.dataPipes[i]).get;
	 let expectedV = {srcGens[i]+1,srcGens[i]};
	 let misMatch = v != expectedV;
	 mismatchCounts[i] <= mismatchCounts[i] + (misMatch ? 1 : 0);
	 let new_srcGens = srcGens[i]+2;
	 if (new_srcGens >= fromInteger(i+1)*truncate(chunk/4))
	    new_srcGens = fromInteger(i)*truncate(chunk/4); 
	 srcGens[i] <= new_srcGens;
      endrule
   end
   
   function Bit#(32) my_add(Tuple2#(Bit#(32),Bit#(32)) xy); match { .x, .y } = xy; return x + y; endfunction
   
   PipeOut#(Vector#(NumEngineServers, Bit#(32))) mismatchCountsPipe <- mkJoinVector(id, map(toPipeOut, mismatchFifos));
   PipeOut#(Bit#(32)) mismatchCountPipe <- mkReducePipe(mkMap(my_add), mismatchCountsPipe);
   
   rule indicate_finish;
      let mc <- toGet(mismatchCountPipe).get();
      mc = mc + mismatchCnt;
      if (iterCnt == 1) begin
	 cf.deq;
	 indication.readDone(mc);
	 mc = 0;
      end
      mismatchCnt <= mc;
      iterCnt <= iterCnt - 1;
   endrule
   
   interface dmaClient = re.dmaClient;
   interface MemreadRequest request;
      method Action startRead(Bit#(32) rp, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
	 indication.started(nw);
	 pointer <= rp;
	 cf.enq(?);
	 numWords  <= nw;
	 burstLen  <= bl;
	 iterCnt <= ic;
	 for(Integer i = 0; i < valueOf(NumEngineServers); i=i+1) begin
	    iterCnts[i] <= ic;
	    mismatchCounts[i] <= 0;
	    srcGens[i] <= fromInteger(i)*(nw/fromInteger(valueOf(NumEngineServers)));      
	 end
      endmethod
   endinterface
endmodule



