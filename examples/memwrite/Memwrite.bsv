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
`include "ConnectalProjectConfig.bsv"
import FIFO::*;
import FIFOF::*;
import Vector::*;
import ClientServer::*;
import GetPut::*;
import ConnectalMemTypes::*;
import MemWriteEngine::*;
import Pipe::*;
import Arith::*;
import ConnectalConfig::*;

`ifdef NumEngineServers
typedef `NumEngineServers NumEngineServers;
`else
typedef 1 NumEngineServers;
`endif

typedef TDiv#(DataBusWidth,32) DataBusWords;

interface MemwriteRequest;
   method Action startWrite(Bit#(32) pointer, Bit#(32) offset, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
   method Action getStateDbg();   
endinterface

interface Memwrite;
   interface MemwriteRequest request;
   interface Vector#(1,MemWriteClient#(DataBusWidth)) dmaClient;
endinterface

interface MemwriteIndication;
   method Action started(Bit#(32) numWords);
   method Action reportStateDbg(Bit#(32) wrCnt, Bit#(32) srcGen);
   method Action writeDone(Bit#(32) v);
endinterface

module  mkMemwrite#(MemwriteIndication indication) (Memwrite);

   Reg#(SGLId)   pointer <- mkReg(0);
   Reg#(Bit#(32))       numWords <- mkReg(0);
   Reg#(Bit#(32))       burstLen <- mkReg(0);
   FIFOF#(void)               cf <- mkSizedFIFOF(1);

   Vector#(NumEngineServers, Reg#(Bit#(32)))         srcGens <- replicateM(mkReg(0));
   Reg#(Bit#(32))                                writeOffset <- mkReg(0);
   Reg#(Bit#(32))                                    iterCnt <- mkReg(0);
   Vector#(NumEngineServers, Reg#(Bit#(32)))        iterCnts <- replicateM(mkReg(0));
   Vector#(NumEngineServers, FIFOF#(void))               cfs <- replicateM(mkSizedFIFOF(1));
   Vector#(NumEngineServers, FIFOF#(Bool))       finishFifos <- replicateM(mkFIFOF);
   MemWriteEngine#(DataBusWidth,DataBusWidth,8,NumEngineServers)                we <- mkMemWriteEngine;
   Bit#(32) chunk = extend(numWords)*4;

   for(Integer i = 0; i < valueOf(NumEngineServers); i=i+1) begin
      rule start (iterCnts[i] > 0);
	 we.writeServers[i].request.put(MemengineCmd{tag:0, sglId:pointer, base:extend(writeOffset)+(fromInteger(i)*chunk), len:truncate(chunk), burstLen:truncate(burstLen*4)});
	 Bit#(32) srcGen = (fromInteger(i) << 28);
	 srcGens[i] <= srcGen;
	 $display("start %d/%d, %h 0x%x %h chunk=%h", i, valueOf(NumEngineServers), srcGen, iterCnts[i], writeOffset, chunk);
	 cfs[i].enq(?);
	 iterCnts[i] <= iterCnts[i]-1;
      endrule
`ifdef MEMENGINE_REQUEST_CYCLES
      rule requestCycles;
	 let reqcycles <- toGet(we.writeServers[i].requestCycles).get();
	 $display("request %d took %d cycles", reqcycles.tag, reqcycles.cycles);
      endrule
`endif
      rule finish;
	 $display("finish %d 0x%x", i, iterCnts[i]);
	 let rv <- we.writeServers[i].done.get;
	 finishFifos[i].enq(rv);
      endrule
      rule src if (cfs[i].notEmpty);
	 Vector#(DataBusWords, Bit#(32)) v;
	 for (Integer j = 0; j < valueOf(DataBusWords); j = j + 1)
	    v[j] = srcGens[i]+fromInteger(j);
	 we.writeServers[i].data.enq(pack(v));
	 let new_srcGen = srcGens[i]+fromInteger(valueOf(DataBusWords));
	 srcGens[i] <= new_srcGen;
	 if (new_srcGen[27:0] >= truncate(numWords))
	    cfs[i].deq;
      endrule
   end
 
   PipeOut#(Vector#(NumEngineServers, Bool)) finishPipe <- mkJoinVector(id, map(toPipeOut, finishFifos));
   PipeOut#(Bool) finishReducePipe <- mkReducePipe(uncurry(booland), finishPipe);

   rule indicate_finish;
      let rv <- toGet(finishReducePipe).get();
      $display("indicate_finish rv=%d iterCnt=%d", rv, iterCnt);
      if (iterCnt == 1) begin
	 cf.deq;
	 indication.writeDone(0);
      end
      iterCnt <= iterCnt - 1;
   endrule
   
   interface MemWriteClient dmaClient = cons(we.dmaClient, nil);
   interface MemwriteRequest request;
       method Action startWrite(Bit#(32) wp, Bit#(32) off, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
	  $display("startWrite pointer=%d offset=%d numWords=%h burstLen=%d iterCnt=%d", wp, off, nw, bl, ic);
	  indication.started(nw);
	  pointer <= wp;
	  cf.enq(?);
	  numWords  <= nw;
	  burstLen  <= bl;
	  iterCnt <= ic;
	  writeOffset <= off*4;
	  for(Integer i = 0; i < valueOf(NumEngineServers); i=i+1)
	     iterCnts[i] <= ic;
       endmethod
   endinterface
endmodule
