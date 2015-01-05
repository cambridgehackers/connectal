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

import Arith::*;
import Pipe::*;
import MemTypes::*;
import MemreadEngine::*;
import Pipe::*;
import HostInterface::*; // for DataBusWidth

`ifdef NumEngineServers
typedef `NumEngineServers NumEngineServers;
`else
typedef 1 NumEngineServers;
`endif
`ifdef NumOutstandingRequests
typedef `NumOutstandingRequests NumOutstandingRequests;
`else
typedef 2 NumOutstandingRequests;
`endif
`ifdef MemreadEngineBufferSize
Integer memreadEngineBufferSize=`MemreadEngineBufferSize;
`else
Integer memreadEngineBufferSize=256;
`endif

interface MemreadRequest;
   method Action startRead(Bit#(32) pointer, Bit#(32) offset, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
   method Action getStateDbg();
endinterface

interface Memread;
   interface MemreadRequest request;
   interface MemReadClient#(DataBusWidth) dmaClient;
endinterface

interface MemreadIndication;
   method Action started(Bit#(32) numWords);
   method Action reportStateDbg(Bit#(32) reportType, Bit#(32) finished, Bit#(32) dataPipeNotEmpty);
   method Action readDone(Bit#(32) mismatchCount);
endinterface

typedef TDiv#(DataBusWidth,32) DataBusWords;

module mkMemread#(MemreadIndication indication) (Memread);

   Reg#(SGLId)   pointer <- mkReg(0);
   Reg#(Bit#(32))       numWords <- mkReg(0);
   Reg#(Bit#(32))       burstLen <- mkReg(0);
   Reg#(Bit#(32))    mismatchCnt <- mkReg(0);
   FIFO#(void)                cf <- mkSizedFIFO(1);
   
   Reg#(Bit#(32))                                   iterCnt <- mkReg(0);
   Reg#(Bit#(32))                                readOffset <- mkReg(0);
   Vector#(NumEngineServers, Reg#(Bit#(32)))       iterCnts <- replicateM(mkReg(0));
   Vector#(NumEngineServers, Reg#(Bit#(32)))   valuesToRead <- replicateM(mkReg(0));
   Vector#(NumEngineServers, Reg#(Bit#(32))) mismatchCounts <- replicateM(mkReg(0));
   MemreadEngineV#(DataBusWidth,NumOutstandingRequests,NumEngineServers) re <- mkMemreadEngineBuff(memreadEngineBufferSize);
   Vector#(NumEngineServers, FIFOF#(Bit#(32))) mismatchFifos <- replicateM(mkFIFOF);
   Bit#(MemOffsetSize) chunk = (extend(numWords)/fromInteger(valueOf(NumEngineServers)))*4;
   
   Vector#(NumEngineServers, RangePipeIfc#(Bit#(32)))     rangePipeIfcs <- replicateM(mkRangePipeOut);
   function PipeOut#(a) getRangePipePipe(RangePipeIfc#(a) rpi); return rpi.pipe; endfunction
   Vector#(NumEngineServers, PipeOut#(Vector#(1,Bit#(32)))) rangePipes = map(mapPipe(replicate), map(getRangePipePipe, rangePipeIfcs));
   Vector#(NumEngineServers, PipeOut#(Vector#(DataBusWords,Bit#(32)))) srcGenPipes <- mapM(mkUnfunnel, rangePipes);
   function Vector#(DataBusWords,Bit#(32)) split(Bit#(DataBusWidth) v); return unpack(v); endfunction
   Vector#(NumEngineServers, PipeOut#(Vector#(DataBusWords,Bit#(32)))) readPipes <- mapM(mkMapPipe(split), re.dataPipes);

   function Vector#(n, Bool) vcompare(Vector#(n, a) x, Vector#(n, a) y) provisos (Eq#(a));
      return map(uncurry(eq), zip(x,y));
   endfunction
   Vector#(NumEngineServers, PipeOut#(Vector#(DataBusWords, Bool)))  mismatchPipes <- mapM(uncurry(mkJoinBuffered(vcompare)), zip(readPipes, srcGenPipes));
   
   Vector#(NumEngineServers, Reg#(Bool)) finishedReg <- replicateM(mkReg(False));

   for(Integer i = 0; i < valueOf(NumEngineServers); i=i+1) begin
      rule start (iterCnts[i] > 0);
	 re.readServers[i].request.put(MemengineCmd{sglId:pointer, base:extend(readOffset)+(fromInteger(i)*chunk), len:truncate(chunk), burstLen:truncate(burstLen*4)});
	 iterCnts[i] <= iterCnts[i]-1;
	 Bit#(32) base = (readOffset/4)+(fromInteger(i)*(truncate(chunk)/4));
	 Bit#(32) limit = base + truncate(chunk)/4;
	 let rangeConfig = RangeConfig { xbase: base, xlimit: limit, xstep: 1 };
	 rangePipeIfcs[i].start(rangeConfig);
	 $display("start %d, %d, %h", i, iterCnts[i], readOffset);
	 finishedReg[i] <= False;
      endrule
      rule finish;
	 $display("finish %d", i);
	 let rv <- re.readServers[i].response.get;
	 finishedReg[i] <= True;
      endrule
      rule check;
	 let bv <- toGet(mismatchPipes[i]).get();
	 let mismatch = !bv[0] || !bv[1];
	 if (mismatch) $display("mismatch bv[0] %d bv[1] %d\n", bv[0], bv[1]);
	 let mc = mismatchCounts[i] + (mismatch ? 1 : 0);

	 let newValuesToRead = valuesToRead[i] - fromInteger(valueOf(DataBusWords));

	 if (valuesToRead[i] <= fromInteger(valueOf(DataBusWords))) begin
	    $display("mismatch count %d", mc);
	    mismatchFifos[i].enq(mc);
	    mc = 0; // restart count
	    newValuesToRead = truncate(chunk/4);
	 end
	 mismatchCounts[i] <= mc;
	 valuesToRead[i] <= newValuesToRead;

      endrule
   end
   
   PipeOut#(Vector#(NumEngineServers, Bit#(32))) mismatchCountsPipe <- mkJoinVector(id, map(toPipeOut, mismatchFifos));
   PipeOut#(Bit#(32)) mismatchCountPipe <- mkReducePipe(uncurry(add), mismatchCountsPipe);
   
   FIFO#(Bit#(2)) reportStateFifo <- mkFIFO();
   rule reportState;
      let v <- toGet(reportStateFifo).get();
	 Vector#(NumEngineServers, Bool) notEmpty = map(pipeOutNotEmpty, re.dataPipes);
	 indication.reportStateDbg(extend(v),
				   extend(pack(readVReg(finishedReg))),
				   extend(pack(notEmpty)));
   endrule

   rule indicate_finish;
      let mc <- toGet(mismatchCountPipe).get();
      mc = mc + mismatchCnt;
      if (iterCnt == 1) begin
	 cf.deq;
	 indication.readDone(mc);
	 mc = 0;
      end
      mismatchCnt <= mc;
      reportStateFifo.enq(1);
      iterCnt <= iterCnt - 1;
   endrule
   
   interface dmaClient = re.dmaClient;
   interface MemreadRequest request;
      method Action startRead(Bit#(32) rp, Bit#(32) off, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
	 indication.started(nw);
	 pointer <= rp;
	 cf.enq(?);
	 numWords  <= nw;
	 burstLen  <= bl;
	 iterCnt <= ic;
	 readOffset <= off*4;
	 for(Integer i = 0; i < valueOf(NumEngineServers); i=i+1) begin
	    iterCnts[i] <= ic;
	    mismatchCounts[i] <= 0;
	    valuesToRead[i] <= truncate(chunk/4);
	    finishedReg[i] <= False;
	 end
	 reportStateFifo.enq(0);
      endmethod
      method Action getStateDbg();
	 reportStateFifo.enq(2);
      endmethod
   endinterface
endmodule



