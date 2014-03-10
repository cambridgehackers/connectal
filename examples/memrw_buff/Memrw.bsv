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
import Connectable::*;

import PortalMemory::*;
import Dma::*;
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

module mkMemrwRequest#(MemrwIndication indication,
		       DmaReadServer#(64) dma_read_server,
		       DmaWriteServer#(64) dma_write_server)(MemrwRequest);

   let readFifo <- mkFIFOF;
   let writeFifo <- mkFIFOF;

   MemreadEngine#(64) re <- mkMemreadEngine(readFifo);
   MemwriteEngine#(64) we <- mkMemwriteEngine(writeFifo);

   Reg#(Bit#(32))        rdIterCnt <- mkReg(0);
   Reg#(Bit#(32))        wrIterCnt <- mkReg(0);
   Reg#(Bit#(32))         numWords <- mkReg(0);
   Reg#(DmaPointer)      rdPointer <- mkReg(0);
   Reg#(DmaPointer)      wrPointer <- mkReg(0);
   Reg#(Bit#(32))         burstLen <- mkReg(0);
   
   mkConnection(re.dmaClient,dma_read_server);
   mkConnection(we.dmaClient,dma_write_server);
   
   rule startRead(rdIterCnt > 0);
      $display("startRead %d", rdIterCnt);
      re.start(rdPointer, numWords, burstLen);
      rdIterCnt <= rdIterCnt-1;
   endrule

   rule finishRead;
      let rv0 <- re.finish;
      if(rdIterCnt==0)
	 indication.readDone;
   endrule
   
   rule readConsume;
      readFifo.deq;
   endrule
   
   rule startWrite(wrIterCnt > 0);
      $display("startWrite %d", wrIterCnt);
      we.start(wrPointer, numWords, burstLen);
      wrIterCnt <= wrIterCnt-1;
   endrule

   rule finishWrite;
      let rv0 <- we.finish;
      if(wrIterCnt==0)
	 indication.writeDone;
   endrule
   
   rule writeProduce;
      writeFifo.enq(1);
   endrule
   
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
endmodule
