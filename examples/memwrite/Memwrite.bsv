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
import MemTypes::*;
import MemwriteEngine::*;
import Pipe::*;
import Arith::*;
import MemUtils::*;
import HostInterface::*;

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

`define FOO
`ifdef FOO
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
   MemwriteEngineV#(DataBusWidth,1,NumEngineServers)                we <- mkMemwriteEngine;
   Bit#(MemOffsetSize) chunk = (extend(numWords)/fromInteger(valueOf(NumEngineServers)))*4;

   for(Integer i = 0; i < valueOf(NumEngineServers); i=i+1) begin
      rule start (iterCnts[i] > 0);
	 we.writeServers[i].request.put(MemengineCmd{sglId:pointer, base:extend(writeOffset)+(fromInteger(i)*chunk), len:truncate(chunk), burstLen:truncate(burstLen*4)});
	 Bit#(32) srcGen = (writeOffset/4)+(fromInteger(i)*truncate(chunk/4));
	 srcGens[i] <= srcGen;
	 $display("start %d, %h %d %h", i, srcGen, iterCnts[i], writeOffset);
	 cfs[i].enq(?);
      endrule
      rule finish;
	 $display("finish %d %d", i, iterCnts[i]);
	 iterCnts[i] <= iterCnts[i]-1;
	 let rv <- we.writeServers[i].response.get;
	 finishFifos[i].enq(rv);
      endrule
      rule src if (cfs[i].notEmpty);
	 Vector#(DataBusWords, Bit#(32)) v;
	 for (Integer j = 0; j < valueOf(DataBusWords); j = j + 1)
	    v[j] = srcGens[i]+fromInteger(j);
	 we.dataPipes[i].enq(pack(v));
	 let new_srcGen = srcGens[i]+fromInteger(valueOf(DataBusWords));
	 srcGens[i] <= new_srcGen;
	 if(new_srcGen == (writeOffset/4)+(fromInteger(i+1)*truncate(chunk/4)))
	    cfs[i].deq;
      endrule
   end
 
   PipeOut#(Vector#(NumEngineServers, Bool)) finishPipe <- mkJoinVector(id, map(toPipeOut, finishFifos));
   PipeOut#(Bool) finishReducePipe <- mkReducePipe(uncurry(booland), finishPipe);

   rule indicate_finish;
      let rv <- toGet(finishReducePipe).get();
      if (iterCnt == 1) begin
	 cf.deq;
	 indication.writeDone(0);
      end
      iterCnt <= iterCnt - 1;
   endrule
   
   interface MemWriteClient dmaClient = cons(we.dmaClient, nil);
   interface MemwriteRequest request;
       method Action startWrite(Bit#(32) wp, Bit#(32) off, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
	  $display("startWrite pointer=%d offset=%d numWords=%h burstLen=%d iterCnt=%d", pointer, off, nw, bl, ic);
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
`else
// this can come in handy for debugging the memserver
module  mkMemwrite#(MemwriteIndication indication) (Memwrite);

   Reg#(SGLId)   pointer <- mkReg(0);
   Reg#(Bit#(32))       numWords <- mkReg(0);
   Reg#(Bit#(32))       burstLen <- mkReg(0);

   Reg#(Bit#(32))         srcGen <- mkReg(0);
   Reg#(Bit#(32))    writeOffset <- mkReg(0);
   Reg#(Bit#(32))       writeEnd <- mkReg(0);
   Reg#(Bit#(32))        iterCnt <- mkReg(0);
   MemWriterBuff#(DataBusWidth,1024)    we <- mkMemWriterBuff;
   FIFOF#(void)               cf <- mkSizedFIFOF(1);
   
   Reg#(Bit#(64)) cycle_cnt <- mkReg(0);
   Reg#(Bit#(64)) last_write_req <- mkReg(0);
   Reg#(Bit#(64)) last_write_data <- mkReg(0);
   Reg#(Bit#(64)) last_write_done_a <- mkReg(0);

   (* fire_when_enabled *)
   rule cycle;
      cycle_cnt <= cycle_cnt+1;
   endrule

   let verbose = False;
   
   rule write_req (writeEnd > writeOffset);
      if (verbose) $display("write_req %d", cycle_cnt-last_write_req);
      last_write_req <= cycle_cnt;
      let nwe = writeEnd-burstLen;
      we.writeServer.writeReq.put(MemRequest{sglId:pointer, offset:extend(nwe), burstLen:truncate(burstLen), tag:0});
      writeEnd <= nwe;
      //if (verbose) $display("write_req %d", nwe);
   endrule
   rule write_data if (srcGen > writeOffset/4);
      if (verbose) $display("write_data %d", cycle_cnt-last_write_data);
      last_write_data <= cycle_cnt;
      let v = {srcGen-1,srcGen-2};
      we.writeServer.writeData.put(MemData{data:v, tag:0, last:False});
      let new_srcGen = srcGen-2;
      srcGen <= new_srcGen;
      //if (verbose) $display("write_data %d", srcGen);
      if (new_srcGen == writeOffset/4)
	 cf.enq(?);
   endrule
   rule write_done_a if (srcGen > writeOffset/4);
      if (verbose) $display("write_done_a %d", cycle_cnt-last_write_done_a);
      last_write_done_a <= cycle_cnt;
      let rv <- we.writeServer.writeDone.get;
   endrule
   rule write_done_b if (srcGen == writeOffset/4);
      let rv <- we.writeServer.writeDone.get;
      iterCnt <= iterCnt-1;
      if(iterCnt==1) begin
	 $display("finish0 %d ", iterCnt);
	 indication.writeDone(0);
      end
      else begin
	 $display("finish1 %d ", iterCnt);
	 cf.deq;
	 let off = writeOffset/4;
	 writeEnd <= (numWords*4)+(off*4);
	 srcGen <= off+numWords;
      end
   endrule
       
   interface MemWriteClient dmaClient = cons(we.writeClient, nil);
   interface MemwriteRequest request;
       method Action startWrite(Bit#(32) wp, Bit#(32) off, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
	  indication.started(nw);
	  if (verbose) $display("startWrite pointer=%d offset=%d numWords=%h burstLen=%d iterCnt=%d", pointer, off, nw, bl, ic);
	  pointer <= wp;
	  numWords  <= nw;
	  burstLen  <= bl*4;
	  iterCnt <= ic;
	  writeOffset <= off*4;
	  writeEnd <= (nw*4)+(off*4);
	  srcGen <= off+nw;
       endmethod
   endinterface
endmodule
`endif
