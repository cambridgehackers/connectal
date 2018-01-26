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
`include "ConnectalProjectConfig.bsv"
import FIFO::*;
import FIFOF::*;
import Vector::*;
import BuildVector::*;
import GetPut::*;
import ClientServer::*;
import Pipe::*;
import ConnectalMemTypes::*;
import MemReadEngine::*;
import ConnectalConfig::*;

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

typedef 14 NumOutstandingRequests;
typedef TMul#(NumOutstandingRequests,TMul#(32,4)) BufferSizeBytes;
module mkReadTest#(ReadTestIndication indication) (ReadTest);

   Reg#(SGLId)   pointer <- mkReg(0);
   Reg#(Bit#(32))       numBytes <- mkReg(0);
   Reg#(Bit#(BurstLenSize)) burstLenBytes <- mkReg(0);
   Reg#(Bit#(32))  itersToFinish <- mkReg(0);
   Reg#(Bit#(32))   itersToStart <- mkReg(0);
   Reg#(Bit#(32))        bytesRead <- mkReg(0);
   Reg#(Bit#(32)) mismatchCounts <- mkReg(0);
   MemReadEngine#(DataBusWidth,DataBusWidth,NumOutstandingRequests,1)        re <- mkMemReadEngineBuff(valueOf(BufferSizeBytes));
   FIFO#(Bit#(32)) checkDoneFifo <- mkFIFO();
   
   rule start (itersToStart > 0);
      $display("Test: request.put");
      re.readServers[0].request.put(MemengineCmd{sglId:pointer, base:0, len:numBytes, tag:0, burstLen:burstLenBytes});
      itersToStart <= itersToStart-1;
   endrule

   Reg#(Bit#(DataBusWidth)) vReg <- mkReg(0);
   Reg#(Bit#(DataBusWidth)) vExpectedReg <- mkReg(0);
   Reg#(Bool)               validReg <- mkReg(False);
   Reg#(Bit#(32))           bytesToRead <- mkReg(0);
   Reg#(Bool)               lastReg <- mkReg(False);
   FIFO#(void)              doneFifo <- mkFIFO;
   rule check;
      // first pipeline stage
      if (re.readServers[0].data.notEmpty()) begin
	 let md <- toGet(re.readServers[0].data).get;
	 //$display("md v=%h tag=%d first=%d last=%d", md.data, md.tag, md.first, md.last);
	 let v = md.data;
	 let rval = bytesRead/4;
	 function Bit#(32) expectedVal(Integer i); return rval+fromInteger(i); endfunction
	 let expectedV = pack(genWith(expectedVal));
	 vReg <= v;
	 vExpectedReg <= expectedV;
	 validReg <= True;
	 let next_bytesRead = bytesRead + fromInteger(valueOf(DataBusWidth))/8;
	 let next_bytesToRead = bytesToRead - fromInteger(valueOf(DataBusWidth))/8;
	 //$display("check next_bytesRead=%d next_bytesToRead=%d last=%d", next_bytesRead, next_bytesToRead, last);
	 if (md.last) begin
	    next_bytesRead = 0;
	    next_bytesToRead = numBytes;
	 end
	 lastReg <= md.last;
	 bytesRead <= next_bytesRead;
	 bytesToRead <= next_bytesToRead;
         if (md.last)
             doneFifo.enq(?);
      end
      else begin
	 validReg <= False;
      end

      // second pipeline stage
      if (validReg) begin
	 let v = vReg;
	 let expectedV = vExpectedReg;
	 let misMatch = v != expectedV;
	 mismatchCounts <= mismatchCounts + (misMatch ? 1 : 0);
	 //$display("Test: check new=%x numBytes=%x bytesRead=%x misMatch=%x read=%x expect=%x", new_bytesRead, numBytes, bytesRead, misMatch, v, expectedV);
	 if (lastReg) begin
	    checkDoneFifo.enq(mismatchCounts);
	 end
      end
   endrule
   
`ifdef MEMENGINE_REQUEST_CYCLES
   rule request_cycles;
      let reqcycles <- toGet(re.readServers[0].requestCycles).get();
      $display("request %d took %d cycles", reqcycles.tag, reqcycles.cycles);
   endrule
`endif
   rule finish if (itersToFinish > 0);
      $display("Test: response.get itersToFinish %x", itersToFinish);
      let mc <- toGet(checkDoneFifo).get();
      doneFifo.deq;
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
	 bytesToRead <= nb;
	 burstLenBytes  <= truncate(bl);
	 itersToFinish <= ic;
	 itersToStart <= ic;
	 mismatchCounts <= 0;
	 bytesRead <= 0;
      endmethod
   endinterface
endmodule
