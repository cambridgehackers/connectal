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
import StmtFSM::*;
import GetPut::*;
import ClientServer::*;
import ConnectalMemTypes::*;
import MemReadEngine::*;
import Pipe::*;

interface MemreadRequest;
   method Action startRead(Bit#(32) pointer, Bit#(32) offset, Bit#(32) numWords, Bit#(32) burstLen);
endinterface

interface Memread;
   interface MemreadRequest request;
   interface MemReadClient#(64) dmaClient;
endinterface

interface MemreadIndication;
   method Action started(Bit#(32) numWords);
   method Action readDone(Bit#(32) mismatchCount);
endinterface

module mkMemread#(MemreadIndication indication) (Memread);

   Reg#(Bit#(32))         numWords <- mkReg(0);
   Reg#(Bit#(32))         burstLen <- mkReg(0);
   
   Reg#(Bit#(32))           srcGen <- mkReg(0);
   Reg#(Bit#(32))    mismatchCount <- mkReg(0);
   MemReadEngine#(64,64,1,1)         re <- mkMemReadEngine;

   let debug = True;
   
   rule check;
      let v <- toGet(re.readServers[0].data).get;
      let expectedV = {srcGen+1,srcGen};
      let misMatch = v.data != expectedV;
      if (debug && misMatch) $display("check %h %h", v, expectedV);
      mismatchCount <= mismatchCount + (misMatch ? 1 : 0);
      if (srcGen+2 == numWords) begin
	 srcGen <= 0;
      end
      else
	 srcGen <= srcGen+2;
      if (v.last) begin
         if (debug) $display("finish");
         indication.readDone(mismatchCount);
      end
   endrule
   
   interface dmaClient = re.dmaClient;
   interface MemreadRequest request;
      method Action startRead(Bit#(32) rp, Bit#(32) off, Bit#(32) nw, Bit#(32) bl);
	 if (debug) $display("startRead rdPointer=%d offset=%d numWords=%h burstLen=%d", rp, off, nw, bl);
	 indication.started(nw);
	 numWords  <= nw;
	 burstLen  <= bl;
	 mismatchCount <= 0;
	 srcGen <= 0;
	 let cmd = MemengineCmd{sglId:rp, base:extend(off*4), len:nw*4, burstLen:truncate(bl*4), tag:0};
	 re.readServers[0].request.put(cmd);
      endmethod
   endinterface
endmodule
