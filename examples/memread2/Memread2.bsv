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

import MemTypes::*;
import MemreadEngine::*;
import Pipe::*;

interface Memread2Request;
   method Action startRead(Bit#(32) pointer, Bit#(32) pointer2, Bit#(32) numWords, Bit#(32) burstLen);
   method Action getStateDbg();   
endinterface

interface Memread2;
   interface Memread2Request request;
   interface ObjectReadClient#(64) dmaClient;
   interface ObjectReadClient#(64) dmaClient2;
endinterface

interface Memread2Indication;
   method Action started(Bit#(32) numWords);
   method Action rData(Bit#(64) v);
   method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) mismatchCount);
   method Action readReq(Bit#(32) v);
   method Action readDone(Bit#(32) mismatchCount);
   method Action mismatch(Bit#(32) offset, Bit#(64) expectedValue, Bit#(64) value);
endinterface

module mkMemread2#(Memread2Indication indication) (Memread2);

   Reg#(Bit#(32))      srcGen <- mkReg(0);
   Reg#(Bit#(32)) mismatchCount <- mkReg(0);
   MemreadEngine#(64,1) re0 <- mkMemreadEngine;
   Reg#(Bit#(32)) mismatchCount2 <- mkReg(0);
   MemreadEngine#(64,1) re1 <- mkMemreadEngine;

   FIFOF#(Bit#(64)) outReg0 <- mkFIFOF;
   FIFOF#(Bit#(64)) outReg1 <- mkFIFOF;
   PipeIn#(Bit#(64)) pi0 = toPipeIn(outReg0);
   PipeIn#(Bit#(64)) pi1 = toPipeIn(outReg1);
   mkConnection(re0.dataPipes[0], pi0);
   mkConnection(re1.dataPipes[0], pi1);

   FIFOF#(Tuple3#(Bit#(32),Bit#(64),Bit#(64))) mismatchFifo <- mkSizedFIFOF(64);

   rule mismatch;
      let tpl = mismatchFifo.first();
      mismatchFifo.deq();
      indication.mismatch(tpl_1(tpl), tpl_2(tpl), tpl_3(tpl));
   endrule

   rule joinreads;
      srcGen <= srcGen+2;
      let expectedV1 = {srcGen+1,srcGen};
      let expectedV2 = {(srcGen+1)*3,srcGen*3};
      let v1 <- toGet(outReg0).get;
      let v2 <- toGet(outReg1).get;

      let misMatch = v1 != expectedV1;
      mismatchCount <= mismatchCount + (misMatch ? 1 : 0);
      if (misMatch)
	 mismatchFifo.enq(tuple3(srcGen, expectedV1, v1));

      let misMatch2 = v2 != expectedV2;
      mismatchCount2 <= mismatchCount2 + (misMatch2 ? 1 : 0);

   endrule
   
   rule done;
      let rv <- re0.readServers[0].response.get;
      let rv2 <- re1.readServers[0].response.get;
      indication.readDone(mismatchCount);
   endrule
   
   interface Memread2Request request;
       method Action startRead(Bit#(32) pointer, Bit#(32) pointer2, Bit#(32) numWords, Bit#(32) bl);
	  $display("startRead(%d %d %d %d)", pointer, pointer2, numWords, bl);
	  re0.readServers[0].request.put(MemengineCmd{pointer:pointer,  base:0, len:numWords*4, burstLen:truncate(bl*4)});
	  re1.readServers[0].request.put(MemengineCmd{pointer:pointer2, base:0, len:numWords*4, burstLen:truncate(bl*4)});
	  indication.started(numWords);
       endmethod

       method Action getStateDbg();
	  indication.reportStateDbg(srcGen, mismatchCount);
       endmethod
   endinterface
   interface ObjectReadClient dmaClient = re0.dmaClient;
   interface ObjectReadClient dmaClient2 = re1.dmaClient;
endmodule
