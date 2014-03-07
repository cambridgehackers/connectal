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

import Vector::*;
import FIFOF::*;
import GetPutF::*;
import FIFO::*;

import PortalMemory::*;
import Dma::*;
import MemreadEngine::*;
import MemwriteEngine::*;
import BRAMFIFOFLevel::*;

interface MemcpyRequest;
   method Action startCopy(Bit#(32) wrPointer, Bit#(32) rdPointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
endinterface

interface MemcpyIndication;
   method Action started;
   method Action done;
endinterface

interface Memcpy;
   interface MemcpyRequest request;
   interface DmaReadClient#(64) dmaReadClient;
   interface DmaWriteClient#(64) dmaWriteClient;
endinterface

module mkMemcpy#(MemcpyIndication indication)(Memcpy);

   FIFOFLevel#(Bit#(64), 32) readFifo <- mkBRAMFIFOFLevel;
   FIFOF#(Bit#(64)) writeFifo <- mkFIFOF;

   MemreadEngine#(64)  re <- mkMemreadEngine(readFifo.fifo);
   MemwriteEngine#(64) we <- mkMemwriteEngine(writeFifo);

   Reg#(Bit#(32))          iterCnt <- mkReg(0);
   Reg#(Bit#(32))         numWords <- mkReg(0);
   Reg#(DmaPointer)      rdPointer <- mkReg(0);
   Reg#(DmaPointer)      wrPointer <- mkReg(0);
   Reg#(Bit#(32))         burstLen <- mkReg(0);
   Reg#(Bit#(32))          xferCnt <- mkReg(0);
   
   rule start(iterCnt > 0);
      re.start(rdPointer, 0, numWords, burstLen);
      we.start(wrPointer, 0, numWords, burstLen);
      iterCnt <= iterCnt-1;
   endrule

   rule finish;
      let rv0 <- re.finish;
      let rv1 <- we.finish;
      if(iterCnt==0)
	 indication.done;
   endrule
   
   rule start_burst_xfer if (readFifo.highWater(truncate(burstLen)) && xferCnt == burstLen);
      xferCnt <= 0;
   endrule      

   rule complete_burst_xfer if (xferCnt < burstLen);
      xferCnt <= xferCnt+1;
      readFifo.fifo.deq;
      writeFifo.enq(readFifo.fifo.first);
   endrule

   interface MemcpyRequest request;
      method Action startCopy(Bit#(32) wp, Bit#(32) rp, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
	 $display("startCopy wrPointer=%d rdPointer=%d numWords=%h burstLen=%d iterCnt=%d", wp, rp, nw, bl, ic);
	 indication.started;
	 // initialized
	 wrPointer <= wp;
	 rdPointer <= rp;
	 numWords  <= nw;
	 iterCnt   <= ic;
	 burstLen  <= bl;
	 xferCnt   <= bl;
      endmethod
   endinterface
   interface DmaReadClient dmaReadClient = re.dmaClient;
   interface DmaWriteClient dmaWriteClient = we.dmaClient;
endmodule
