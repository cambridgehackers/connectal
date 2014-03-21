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
import SpecialFIFOs::*;
import FIFOF::*;
import Connectable::*;

import AxiMasterSlave::*;
import Dma::*;
import MemwriteEngine::*;

interface MemwriteRequest;
   method Action startWrite(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
   method Action getStateDbg();   
endinterface

interface MemwriteIndication;
   method Action started(Bit#(32) numWords);
   method Action reportStateDbg(Bit#(32) wrCnt, Bit#(32) srcGen);
   method Action writeDone(Bit#(32) v);
endinterface

module  mkMemwriteRequest#(MemwriteIndication indication,
			   DmaWriteServer#(64) dma_write_server)(MemwriteRequest);

   Reg#(Bit#(32))           srcGen <- mkReg(0);
   FIFOF#(Bit#(64))      writeFifo <- mkFIFOF;
   let                          we <- mkMemwriteEngine(1, writeFifo);

   Reg#(DmaPointer)        pointer <- mkReg(0);
   Reg#(Bit#(32))         numWords <- mkReg(0);
   Reg#(Bit#(32))         burstLen <- mkReg(0);
   Reg#(Bit#(32))          iterCnt <- mkReg(0);
   
   mkConnection(we.dmaClient,dma_write_server);

   rule start (iterCnt > 0);
      iterCnt <= iterCnt-1;
      we.start(pointer, 0, numWords*4, burstLen*4);
   endrule
   
   rule finish;
      let rv <- we.finish;
      if (iterCnt == 0)
	 indication.writeDone(0);
   endrule
   
   rule src (numWords > 0);
      if (srcGen+2 == numWords)
	 srcGen <= 0;
      else
	 srcGen <= srcGen+2;
      writeFifo.enq({srcGen+1,srcGen});
   endrule

   method Action startWrite(Bit#(32) wp, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
      $display("startWrite pointer=%d numWords=%h burstLen=%d iterCnt=%d", pointer, nw, bl, ic);
      indication.started(nw);
      pointer <= wp;
      numWords <= nw;
      burstLen <= bl;
      iterCnt <= ic;
      srcGen <= 0;
   endmethod
   
   method Action getStateDbg();
      indication.reportStateDbg(iterCnt, srcGen);
   endmethod
   
endmodule