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
import FIFO::*;
import ClientServer::*;
import GetPut::*;
import Pipe::*;
import Vector::*;

import ConnectalMemory::*;
import MemTypes::*;
import MemreadEngine::*;
import MemwriteEngine::*;

interface MemrwRequest;
   method Action start(Bit#(32) wrPointer, Bit#(32) rdPointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
endinterface

interface MemrwIndication;
   method Action started;
   method Action readDone;
   method Action writeDone;
endinterface

interface Memrw;
   interface MemrwRequest request;
   interface Vector#(1, MemReadClient#(64)) dmaReadClient;
   interface Vector#(1, MemWriteClient#(64)) dmaWriteClient;
endinterface

module mkMemrw#(MemrwIndication indication)(Memrw);


   MemreadEngine#(64,1,1)  re <- mkMemreadEngine;
   MemwriteEngine#(64,2,1) we <- mkMemwriteEngine;
   
   Reg#(Bit#(32))        rdIterCnt <- mkReg(0);
   Reg#(Bit#(32))        wrIterCnt <- mkReg(0);
   Reg#(Bit#(32))         numWords <- mkReg(0);
   Reg#(SGLId)   rdPointer <- mkReg(0);
   Reg#(SGLId)   wrPointer <- mkReg(0);
   Reg#(Bit#(32))         burstLen <- mkReg(0);
   
   rule startRead(rdIterCnt > 0);
      $display("startRead %d", rdIterCnt);
      re.readServers[0].request.put(MemengineCmd{sglId:rdPointer, base:0, len:numWords*4, burstLen:truncate(burstLen*4)});
      rdIterCnt <= rdIterCnt-1;
   endrule

   rule finishRead;
      let rv0 <- re.readServers[0].response.get;
      if(rdIterCnt==0)
	 indication.readDone;
   endrule
   
   rule readConsume;
      re.dataPipes[0].deq;
   endrule
   
   rule startWrite(wrIterCnt > 0);
      $display("startWrite %d", wrIterCnt);
      we.writeServers[0].request.put(MemengineCmd{sglId:wrPointer, base:0, len:numWords*4, burstLen:truncate(burstLen*4)});
      wrIterCnt <= wrIterCnt-1;
   endrule

   rule finishWrite;
      let rv0 <- we.writeServers[0].response.get;
      if(wrIterCnt==0)
	 indication.writeDone;
   endrule
   
   rule writeProduce;
      we.dataPipes[0].enq(1);
   endrule
   
   interface MemrwRequest request;
   method Action start(Bit#(32) wp, Bit#(32) rp, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
      $display("start wrPointer=%d rdPointer=%d numWords=%h burstLen=%d iterCnt=%d", wp, rp, nw, bl, ic);
      indication.started;
      // initialized
      wrPointer <= wp;
      rdPointer <= rp;
      numWords  <= nw;
      rdIterCnt   <= ic;
      wrIterCnt   <= ic;
      burstLen  <= bl;
   endmethod
   endinterface
   interface MemReadClient dmaReadClient = cons(re.dmaClient, nil);
   interface MemWriteClient dmaWriteClient = cons(we.dmaClient, nil);
   
endmodule
