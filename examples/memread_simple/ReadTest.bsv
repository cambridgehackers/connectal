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
import GetPut::*;
import ClientServer::*;
import Pipe::*;
import MemTypes::*;
import MemreadEngine::*;
import Pipe::*;
import HostInterface::*; // for DataBusWidth

interface ReadTestRequest;
   method Action startRead(Bit#(32) pointer, Bit#(32) numBytes, Bit#(32) burstLenInBytes, Bit#(32) iterCnt);
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
   Reg#(Bit#(BurstLenSize)) burstLenInBytes <- mkReg(0);
   Reg#(Bit#(32))  itersToFinish <- mkReg(0);
   Reg#(Bit#(32))   itersToStart <- mkReg(0);
   Reg#(Bit#(32))        srcGens <- mkReg(0);
   Reg#(Bit#(32)) mismatchCounts <- mkReg(0);
   MemreadEngine#(DataBusWidth,2,1) re <- mkMemreadEngine;

   rule start (itersToStart > 0);
      re.readServers[0].request.put(MemengineCmd{sglId:pointer, base:0, len:numBytes, burstLen:burstLenInBytes});
      itersToStart <= itersToStart-1;
   endrule

   function Bit#(32) expectedVal(Integer i); return srcGens+fromInteger(i); endfunction
   rule check;
      let v <- toGet(re.readServers[0].data).get;
      let expectedV = pack(genWith(expectedVal));
      let misMatch = v.data != expectedV;
      mismatchCounts <= mismatchCounts + (misMatch ? 1 : 0);
      let new_srcGens = srcGens+2;
      if (v.last) begin
	 new_srcGens = 0;
         if (itersToFinish == 1) begin
	    indication.readDone(mismatchCounts);
         end
         itersToFinish <= itersToFinish - 1;
      end
      srcGens <= new_srcGens;
   endrule

   interface dmaClient = cons(re.dmaClient, nil);
   interface ReadTestRequest request;
      method Action startRead(Bit#(32) rp, Bit#(32) nb, Bit#(32) bl, Bit#(32) ic) if (itersToStart == 0 && itersToFinish == 0);
	 pointer <= rp;
	 numBytes <= nb;
	 burstLenInBytes  <= truncate(bl);
	 itersToFinish <= ic;
	 itersToStart <= ic;
	 mismatchCounts <= 0;
	 srcGens <= 0;
      endmethod
   endinterface
endmodule
