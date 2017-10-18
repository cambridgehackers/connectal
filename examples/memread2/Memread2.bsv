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
import Vector::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;
import ConnectalMemTypes::*;
import MemReadEngine::*;
import Pipe::*;

interface Memread2Request;
   method Action startRead(Bit#(32) pointer, Bit#(32) pointer2, Bit#(32) numWords, Bit#(32) burstLen);
   method Action getStateDbg();   
endinterface

interface Memread2;
   interface Memread2Request request;
   interface Vector#(2, MemReadClient#(64)) dmaClients;
endinterface

interface Memread2Indication;
   method Action started(Bit#(32) numWords);
   method Action rData(Bit#(64) v);
   method Action reportStateDbg(Bit#(32) x, Bit#(32) y);
   method Action readReq(Bit#(32) v);
   method Action readDone(Bit#(32) mismatchCount);
   method Action mismatch(Bit#(32) offset, Bit#(64) expectedValue, Bit#(64) value);
endinterface

module mkMemread2#(Memread2Indication indication) (Memread2);

   Reg#(Bit#(32))     srcGen0 <- mkReg(0);
   Reg#(Bit#(32))     srcGen1 <- mkReg(0);
   Reg#(Bit#(32)) mismatchCount0 <- mkReg(0);
   Reg#(Bit#(32)) mismatchCount1 <- mkReg(0);
   MemReadEngine#(64,64,1,1) re0 <- mkMemReadEngine;
   MemReadEngine#(64,64,1,1) re1 <- mkMemReadEngine;

   FIFOF#(Bit#(64)) outReg0 <- mkFIFOF;
   FIFOF#(Bit#(64)) outReg1 <- mkFIFOF;
   PipeIn#(Bit#(64)) pi0 = toPipeIn(outReg0);
   PipeIn#(Bit#(64)) pi1 = toPipeIn(outReg1);
   FIFOF#(Bit#(1)) doneReg0 <- mkFIFOF;
   FIFOF#(Bit#(1)) doneReg1 <- mkFIFOF;
   rule re0_read;
      let v <- toGet(re0.readServers[0].data).get;
      toPut(pi0).put(v.data);
      if (v.last)
         doneReg0.enq(0);
   endrule
   rule re1_read;
      let v <- toGet(re1.readServers[0].data).get;
      toPut(pi1).put(v.data);
      if (v.last)
         doneReg1.enq(0);
   endrule

   Reg#(Bool)         valid0Reg <- mkReg(False);
   Reg#(Bit#(64)) v0Reg <- mkReg(0);
   Reg#(Bit#(64)) v0ExpectedReg <- mkReg(0);
   rule read0;
      // first stage of pipeline
      if (outReg0.notEmpty) begin
	 srcGen0 <= srcGen0+2;
	 v0ExpectedReg  <= {srcGen0+1,srcGen0};
	 let v0 <- toGet(outReg0).get;
	 v0Reg <= v0;
	 valid0Reg <= True;
      end
      else begin
	 valid0Reg <= False;
      end
      
      // second stage of pipeline
      if (valid0Reg) begin
	 let mm = v0Reg != v0ExpectedReg;
	 mismatchCount0 <= mismatchCount0 + (mm ? 1 : 0);
	 if (mm) indication.mismatch(0, v0ExpectedReg, v0Reg);
      end
   endrule

   Reg#(Bool)         valid1Reg <- mkReg(False);
   Reg#(Bit#(64)) v1Reg <- mkReg(0);
   Reg#(Bit#(64)) v1ExpectedReg <- mkReg(0);
   rule read1;
      // first stage of pipeline
      if (outReg1.notEmpty) begin
	 srcGen1 <= srcGen1+2;
	 v1ExpectedReg <= {(srcGen1+1)*3,srcGen1*3};
	 let v1 <- toGet(outReg1).get;
	 v1Reg <= v1;
	 valid1Reg <= True;
      end
      else begin
	 valid1Reg <= False;
      end

      // second stage of pipeline
      if (valid1Reg) begin
	 let mm = v1Reg != v1ExpectedReg;
	 mismatchCount1 <= mismatchCount1 + (mm ? 1 : 0);
	 if (mm) indication.mismatch(1, v1ExpectedReg, v1Reg); 
      end
   endrule
   
   rule done;
      doneReg0.deq;
      doneReg1.deq;
      indication.readDone(mismatchCount1+mismatchCount0);
   endrule
   
   interface Memread2Request request;
       method Action startRead(Bit#(32) pointer, Bit#(32) pointer2, Bit#(32) numWords, Bit#(32) bl);
	  $display("startRead(%d %d %d %d)", pointer, pointer2, numWords, bl);
	  re0.readServers[0].request.put(MemengineCmd{sglId:pointer,  base:0, len:numWords*4, burstLen:truncate(bl*4), tag:0});
	  re1.readServers[0].request.put(MemengineCmd{sglId:pointer2, base:0, len:numWords*4, burstLen:truncate(bl*4), tag:0});
	  indication.started(numWords);
       endmethod

       method Action getStateDbg();
	  Bit#(16) sg0 = truncate(srcGen0);
	  Bit#(16) sg1 = truncate(srcGen1);
	  Bit#(16) mm0 = truncate(mismatchCount0);
	  Bit#(16) mm1 = truncate(mismatchCount1);
	  indication.reportStateDbg({sg0,sg1}, {mm0,mm1});
       endmethod
   endinterface
   interface MemReadClient dmaClients = cons(re0.dmaClient, cons(re1.dmaClient, nil));
endmodule
