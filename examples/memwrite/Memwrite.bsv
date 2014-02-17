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
import GetPutF::*;

import AxiMasterSlave::*;
import Dma::*;

interface MemwriteRequest;
   method Action startWrite(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
   method Action getStateDbg();   
endinterface

interface Memwrite;
   interface MemwriteRequest request;
   interface DmaWriteClient#(64) dmaClient;
endinterface

interface MemwriteIndication;
   method Action started(Bit#(32) numWords);
   method Action reportStateDbg(Bit#(32) wrCnt, Bit#(32) srcGen);
   method Action writeReq(Bit#(32) v);
   method Action writeDone(Bit#(32) v);
endinterface

module  mkMemwrite#(MemwriteIndication indication) (Memwrite);

   Reg#(Bit#(32))         numWords <- mkReg(0);
   Reg#(Bit#(32))           srcGen <- mkReg(0);
   Reg#(Bit#(32))            wrCnt <- mkReg(0);
   
   Reg#(Bit#(DmaOffsetSize)) wrOff <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) delta <- mkReg(0);

   Reg#(DmaPointer)      wrPointer <- mkReg(0);
   Reg#(Bit#(8))          burstLen <- mkReg(0);
   Reg#(Bit#(32))        wrIterCnt <- mkReg(0);
   FIFO#(Bool)                acks <- mkSizedFIFO(32);
   
   rule writeReq(wrIterCnt > 0 && wrCnt == numWords>>1);
      wrCnt <= 0;
      wrIterCnt <= wrIterCnt-1;
      wrOff <= 0;
   endrule
   
   interface DmaWriteClient dmaClient;
      interface GetF writeReq;
	 method ActionValue#(DmaRequest) get() if (wrIterCnt > 0 && wrCnt < numWords>>1);
	    //$display("wrReq: pointer=%d offset=%h burstlen=%d", wrPointer, wrOff, burstLen);
	    wrCnt <= wrCnt+extend(burstLen);
	    wrOff <= wrOff + delta;
	    acks.enq(wrIterCnt == 1 && wrCnt == (numWords>>1)-extend(burstLen));
	    return DmaRequest {pointer: wrPointer, offset: wrOff, burstLen: burstLen, tag: 1};
	 endmethod
	 method Bool notEmpty;
	    return (wrIterCnt > 0 && wrCnt < numWords>>1);
	 endmethod
      endinterface : writeReq
      interface GetF writeData;
	 method ActionValue#(DmaData#(64)) get();
	    //$display("mkMemWrite.dmaClient.writeData::get dmadata=%h, tag=%h", dmadata, tag);
	    if (srcGen+2 == numWords)
	       srcGen <= 0;
	    else
	       srcGen <= srcGen+2;
	    let dmadata = {srcGen+1,srcGen};
	    return DmaData{data:dmadata, tag: 1};
	 endmethod
	 method Bool notEmpty;
	    return True;
	 endmethod
      endinterface : writeData
      interface PutF writeDone;
	 method Action put(Bit#(6) tag);
	    if (acks.first)
	       indication.writeDone(0);
	    acks.deq;
	 endmethod
	 method Bool notFull;
	    return True;
	 endmethod
      endinterface : writeDone
   endinterface : dmaClient

   interface MemwriteRequest request;
       method Action startWrite(Bit#(32) pointer, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
	  $display("startWrite pointer=%d numWords=%h burstLen=%d iterCnt=%d", pointer, nw, bl, ic);
	  indication.started(nw);
	  // initialized
	  wrPointer <= pointer;
	  numWords <= nw;
	  burstLen <= truncate(bl);
	  delta <= 8*extend(bl);
	  wrIterCnt <= ic;
	  // reset
	  wrCnt <= 0;
	  wrOff <= 0;
	  srcGen <= 0;
       endmethod
       method Action getStateDbg();
	  indication.reportStateDbg(wrCnt, srcGen);
       endmethod
   endinterface
endmodule