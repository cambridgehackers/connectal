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
import BuildVector::*;
import GetPut::*;
import ClientServer::*;

import Pipe::*;
import MemTypes::*;
import MemreadEngine::*;
import Pipe::*;
import HostInterface::*;

interface ReadTestRequest;
   method Action startRead(Bit#(32) pointer, Bit#(32) numBytes, Bit#(32) burstLen, Bit#(32) iterCnt);
endinterface

interface ReadTest;
   interface ReadTestRequest request;
   interface Vector#(1,MemReadClient#(DataBusWidth)) dmaClient;
endinterface

interface ReadTestIndication;
   method Action readDone(Bit#(32) mismatchCount);
endinterface

module mkReadTest#(ReadTestIndication indication) (ReadTest);

   Reg#(SGLId)   pointer <- mkReg(0);
   Reg#(Bit#(32))       numBytes <- mkReg(0);
   Reg#(Bit#(BurstLenSize)) burstLenBytes <- mkReg(0);
   Reg#(Bit#(32))  itersToFinish <- mkReg(0);
   Reg#(Bit#(32))   itersToStart <- mkReg(0);
   Reg#(Bit#(32))        wordsRead <- mkReg(0);
   Reg#(Bit#(32)) mismatchCounts <- mkReg(0);
   MemreadEngine#(DataBusWidth,1,1)        re <- mkMemreadEngine;
   FIFO#(Bit#(32)) checkDoneFifo <- mkFIFO();
   
   rule start (itersToStart > 0);
      $display("Test: request.put");
      re.readServers[0].request.put(MemengineCmd{sglId:pointer, base:0, len:numBytes, burstLen:burstLenBytes});
      itersToStart <= itersToStart-1;
   endrule

   rule check;
      let v <- toGet(re.dataPipes[0]).get;
      let rval = wordsRead/4;
      let expectedV = {rval+1,rval};
      let misMatch = v != expectedV;
      mismatchCounts <= mismatchCounts + (misMatch ? 1 : 0);
      let new_wordsRead = wordsRead + fromInteger(valueOf(DataBusWidth))/8;
      //$display("Test: check new=%x numBytes=%x wordsRead=%x misMatch=%x read=%x expect=%x", new_wordsRead, numBytes, wordsRead, misMatch, v, expectedV);
      if (new_wordsRead >= truncate(numBytes)) begin
	 new_wordsRead = 0;
	 checkDoneFifo.enq(mismatchCounts);
      end
      wordsRead <= new_wordsRead;
   endrule
   
   rule finish if (itersToFinish > 0);
      $display("Test: response.get itersToFinish %x", itersToFinish);
      let mc <- toGet(checkDoneFifo).get();
      let rv <- re.readServers[0].response.get;
      if (itersToFinish == 1) begin
	 indication.readDone(mismatchCounts);
      end
      itersToFinish <= itersToFinish - 1;
   endrule
   
   interface dmaClient = vec(re.dmaClient);
   interface ReadTestRequest request;
      method Action startRead(Bit#(32) rp, Bit#(32) nb, Bit#(32) bl, Bit#(32) ic) if (itersToStart == 0 && itersToFinish == 0);
         $display("startRead pointer=%x numBytes %x burstLen %x iteration %x", rp, nb, bl, ic);
	 pointer <= rp;
	 numBytes  <= nb;
	 burstLenBytes  <= truncate(bl);
	 itersToFinish <= ic;
	 itersToStart <= ic;
	 mismatchCounts <= 0;
	 wordsRead <= 0;
      endmethod
   endinterface
endmodule
