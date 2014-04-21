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
import BRAMFIFO::*;
import Vector::*;
import StmtFSM::*;
import Connectable::*;

import PortalMemory::*;
import Dma::*;
import MemreadEngine::*;
import MemwriteEngine::*;

interface MemcpyRequest;
   method Action startCopy(Bit#(32) wrPointer, Bit#(32) rdPointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
endinterface

interface MemcpyIndication;
   method Action started;
   method Action done;
endinterface

interface Memcpy;
   interface MemcpyRequest request;
endinterface

module mkMemcpy#(MemcpyIndication indication, 
		 Vector#(4, ObjectReadServer#(64)) dma_read_servers, 
		 Vector#(4, ObjectWriteServer#(64)) dma_write_servers) (Memcpy);

   Vector#(4,FIFOF#(Bit#(64))) rdFifos <- replicateM(mkFIFOF);
   Vector#(4,FIFOF#(Bit#(64))) wrFifos <- replicateM(mkFIFOF);
   Vector#(4,MemreadEngine#(64))   res <- mapM(uncurry(mkMemreadEngine), zip(replicate(1), rdFifos));
   Vector#(4,MemwriteEngine#(64))  wes <- mapM(uncurry(mkMemwriteEngine), zip(replicate(1), wrFifos));

   function ObjectWriteClient#(64) wdc(MemwriteEngine#(64) we) = we.dmaClient;
   function ObjectReadClient#(64) rdc(MemreadEngine#(64) re) = re.dmaClient;
   zipWithM(mkConnection, map(rdc,res), dma_read_servers);
   zipWithM(mkConnection, map(wdc,wes), dma_write_servers);
   
   FIFO#(void)         startRdFifo <- mkFIFO;
   FIFO#(void)         startWrFifo <- mkFIFO;
   Reg#(Bit#(32))        rdIterCnt <- mkReg(0);
   Reg#(Bit#(32))        wrIterCnt <- mkReg(0);
   Reg#(ObjectPointer)   rdPointer <- mkReg(0);
   Reg#(ObjectPointer)   wrPointer <- mkReg(0);
   Reg#(Bit#(32))         burstLen <- mkReg(0);
   Reg#(Bit#(32))         numWords <- mkReg(0);
   Reg#(Bit#(32))      startRdBase <- mkReg(0);
   Reg#(Bit#(32))      startWrBase <- mkReg(0);
   Reg#(Bit#(3))        startRdPtr <- mkReg(0);
   Reg#(Bit#(3))        startWrPtr <- mkReg(0);   
   
   Stmt startRdStmt = seq
		       startRdBase <= 0;
		       for(startRdPtr <= 0; startRdPtr < 4; startRdPtr <= startRdPtr+1)
			  (action
			      $display("start_read:%d %h %h %h (%d)", startRdPtr, startRdBase, numWords, burstLen*4, rdIterCnt);
			      res[startRdPtr].start(rdPointer, extend(startRdBase), numWords, burstLen*4);
			      startRdBase <= startRdBase+numWords;
			   endaction);
		    endseq;
   FSM startRdFSM <- mkFSM(startRdStmt);

   Stmt startWrStmt = seq
		       startWrBase <= 0;
		       for(startWrPtr <= 0; startWrPtr < 4; startWrPtr <= startWrPtr+1)
			  (action
			      $display("start_write:%d %h %h %h (%d)", startWrPtr, startWrBase, numWords, burstLen*4, wrIterCnt);
			      wes[startWrPtr].start(wrPointer, extend(startWrBase), numWords, burstLen*4);
			      startWrBase <= startWrBase+numWords;
			   endaction);
		    endseq;
   FSM startWrFSM <- mkFSM(startWrStmt);

   rule start_read(rdIterCnt > 0);
      startRdFifo.deq;
      startRdFSM.start;
      rdIterCnt <= rdIterCnt-1;
   endrule

   rule start_write(wrIterCnt > 0);
      startWrFifo.deq;
      startWrFSM.start;
      wrIterCnt <= wrIterCnt-1;
   endrule
   
   rule read_finish;
      for(Integer i = 0; i < 4; i=i+1) begin
	 $display("read_finish: %d (%d)", i, rdIterCnt);
	 let rv <- res[i].finish;
      end
      if (rdIterCnt > 0)
	 startRdFifo.enq(?);
   endrule

   rule write_finish;
      for(Integer i = 0; i < 4; i=i+1) begin
	 $display("write_finish: %d (%d)", i, wrIterCnt);
	 let rv <- wes[i].finish;
      end
      if (wrIterCnt == 0)
	 indication.done;
      else
	 startWrFifo.enq(?);
   endrule
   
   for(Integer i = 0; i < 4; i=i+1) 
      rule xfer;
	 rdFifos[i].deq;
	 wrFifos[i].enq(rdFifos[i].first);
      endrule
   
   interface MemcpyRequest request;
      method Action startCopy(Bit#(32) wp, Bit#(32) rp, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
	 $display("startCopy wrPointer=%d rdPointer=%d numWords=%h burstLen=%d iterCnt=%d", wp, rp, nw, bl, ic);
	 indication.started;
	 // initialized
	 wrPointer <= wp;
	 rdPointer <= rp;
	 numWords  <= nw;
	 wrIterCnt <= ic;
	 rdIterCnt <= ic;
	 burstLen  <= bl;
	 startRdFifo.enq(?);
	 startWrFifo.enq(?);
      endmethod
   endinterface
endmodule
