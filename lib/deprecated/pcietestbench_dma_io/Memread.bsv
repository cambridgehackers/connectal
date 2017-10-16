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
import ConnectalMemTypes::*;
import MemReadEngine::*;

interface MemreadRequest;
   method Action startRead(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
   method Action getStateDbg();   
endinterface

interface Memread;
   interface MemreadRequest request;
   interface MemReadClient#(64) dmaClient;
endinterface

interface MemreadIndication;
   method Action started(Bit#(32) numWords);
   method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) mismatchCount);
   method Action readDone(Bit#(32) mismatchCount);
endinterface

module mkMemread#(MemreadIndication indication) (Memread);

   Reg#(SGLId)        pointer <- mkReg(0);
   Reg#(Bit#(32))         numWords <- mkReg(0);
   Reg#(Bit#(32))         burstLen <- mkReg(0);
   Reg#(Bit#(32))          iterCnt <- mkReg(0);
   
   Reg#(Bit#(32))           srcGen <- mkReg(0);
   Reg#(Bit#(32))    mismatchCount <- mkReg(0);
   FIFOF#(Bit#(64))       readFifo <- mkFIFOF;
   let                          re <- mkMemReadEngine(1, readFifo);
   
   rule start (iterCnt > 0);
      iterCnt <= iterCnt-1;
      re.start(pointer, 0, numWords*4, burstLen*4);
   endrule
   
   rule finish;
      let rv <- re.finish;
      if (iterCnt == 0)
	 indication.readDone(mismatchCount);
   endrule
   
   rule check;
      readFifo.deq;
      let v = readFifo.first;
      let expectedV = {srcGen+1,srcGen};
      let misMatch = v != expectedV;
      mismatchCount <= mismatchCount + (misMatch ? 1 : 0);
      if (srcGen+2 == numWords)
	 srcGen <= 0;
      else
	 srcGen <= srcGen+2;
   endrule
   
   interface MemReadClient dmaClient = re.dmaClient;
   interface MemreadRequest request;
      method Action startRead(Bit#(32) rp, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
	 $display("startRead rdPointer=%d numWords=%h burstLen=%d iterCnt=%d", rp, nw, bl, ic);
	 indication.started(nw);
	 pointer <= rp;
	 numWords  <= nw;
	 burstLen  <= bl;
	 iterCnt <= ic;
	 mismatchCount <= 0;
	 srcGen <= 0;
      endmethod
      method Action getStateDbg();
	 indication.reportStateDbg(iterCnt, mismatchCount);
      endmethod
   endinterface
endmodule
