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
   method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) srcGen);
   method Action writeReq(Bit#(32) v);
   method Action writeDone(Bit#(32) v);
endinterface

module  mkMemwrite#(MemwriteIndication indication) (Memwrite);

   Reg#(Bit#(32))         wrPointer <- mkReg(0); 
   Reg#(Bit#(32))             wrCnt <- mkReg(0);
   Reg#(Bit#(32))            srcGen <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) offset <- mkReg(0);

   Reg#(Bit#(8))           burstLen <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize))  delta <- mkReg(0);
   Reg#(Bit#(32))           iterCnt <- mkReg(0);
   
   Reg#(Bit#(8))         burstCount <- mkReg(0);
   FIFOF#(Bit#(6))         dataTags <- mkSizedFIFOF(32);
   FIFOF#(Bit#(6))         doneTags <- mkSizedFIFOF(32);
   
   let reqFifo <- mkFIFO;

   rule start_write if (wrCnt == 0 && srcGen == 0);
      Bit#(32) pointer = tpl_1(reqFifo.first);
      Bit#(32) numWords = tpl_2(reqFifo.first);
      Bit#(32) bl = tpl_3(reqFifo.first);
      wrPointer <= pointer;
      wrCnt <= numWords>>1;
      srcGen <= numWords;
      offset <= 0;
      burstLen <= truncate(bl);
      delta <= 8*extend(bl);
      iterCnt <= iterCnt-1;
      if(iterCnt==1) 
	 reqFifo.deq;
      $display("start_write %d", iterCnt);
   endrule
      
   interface DmaWriteClient dmaClient;
      interface GetF writeReq;
	 method ActionValue#(DmaRequest) get() if (wrCnt > 0);
	    wrCnt <= wrCnt-extend(burstLen);
	    offset <= offset + delta;
	    //else if (wrCnt[5:0] == 6'b0)
	    //    indication.writeReq(wrCnt);
	    Bit#(6) tag = truncate(offset >> 5);
	    dataTags.enq(tag);
	    doneTags.enq(tag);
	    //$display("mkMemWrite.dmaClient.writeReq::get wrCnt=%d, tag=%d", wrCnt, tag);
	    return DmaRequest {pointer: wrPointer, offset: offset, burstLen: burstLen, tag: tag};
	 endmethod
	 method Bool notEmpty;
	    return wrCnt > 0;
	 endmethod
      endinterface : writeReq
      interface GetF writeData;
	 method ActionValue#(DmaData#(64)) get();
	    if (burstCount == 0) begin // starting a new burst
	       burstCount <= burstLen -1;
	    end
	    else begin
	       burstCount <= burstCount-1;
	       if (burstCount == 1) begin // ending a burst
		  dataTags.deq();
	       end
	    end
	    if (srcGen == 2 && iterCnt == 0)
	       indication.writeDone(0);
	    let tag = dataTags.first();
	    srcGen <= srcGen-2;
	    let dmadata = {srcGen-1,srcGen};
	    //$display("mkMemWrite.dmaClient.writeData::get dmadata=%h, tag=%h", dmadata, tag);
	    return DmaData{data:dmadata, tag: tag};
	 endmethod
	 method Bool notEmpty;
	    return True;
	 endmethod
      endinterface : writeData
      interface PutF writeDone;
	 method Action put(Bit#(6) tag);
	    if (tag != doneTags.first)
	       $display("doneTag mismatch tag=%h doneTag=%h", tag, doneTags.first);
	    doneTags.deq();
	 endmethod
	 method Bool notFull = doneTags.notFull;
      endinterface : writeDone
   endinterface : dmaClient

   interface MemwriteRequest request;
       method Action startWrite(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) bl, Bit#(32) ic);
	  $display("mkMemWrite::startWrite(%d %d %d)", pointer, numWords, bl);
	  indication.started(numWords*ic);
          reqFifo.enq(tuple3(pointer,numWords,bl));
	  iterCnt <= ic;
       endmethod
       method Action getStateDbg();
	  indication.reportStateDbg(wrCnt, srcGen);
       endmethod
   endinterface
endmodule