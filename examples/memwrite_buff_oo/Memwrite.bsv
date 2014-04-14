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
import GetPut::*;

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
			   ObjectWriteServer#(64) dma_write_server)(MemwriteRequest);
   
   Reg#(ObjectPointer)     wrPointer <- mkReg(0);
   Reg#(Bit#(8))            burstLen <- mkReg(0);
   Reg#(Bit#(32))             reqLen <- mkReg(0);

   Reg#(Bit#(6))               wrTag <- mkReg(0);
   Reg#(Bit#(32))            respCnt <- mkReg(0);
   Reg#(Bit#(32))           burstCnt <- mkReg(0);
   Reg#(Bit#(32))              wrOff <- mkReg(0);
   Reg#(Bit#(32))             srcGen <- mkReg(0);
   Reg#(Bit#(32))            iterCnt <- mkReg(0);
   FIFO#(Bit#(6))            tagFifo <- mkSizedFIFO(6);
   
   rule wrReq if (wrOff < reqLen);
      let new_wrOff = wrOff + extend(burstLen);
      dma_write_server.writeReq.put(ObjectRequest { pointer: wrPointer, offset: extend(wrOff), burstLen: burstLen, tag: wrTag});      
      if (new_wrOff >= reqLen) begin
	 if (iterCnt > 1) 
	    new_wrOff = 0;
	 iterCnt <= iterCnt-1;
      end
      wrOff <= new_wrOff;
      wrTag <= wrTag+1;
      tagFifo.enq(wrTag);
   endrule
   
   rule wrData;
      let new_burstCnt = burstCnt+(64/8);
      let new_srcGen = srcGen+2;
      if (new_burstCnt >= extend(burstLen)) begin 
	 new_burstCnt = 0;
	 new_srcGen = 0;
	 tagFifo.deq;
      end
      burstCnt <= new_burstCnt;
      srcGen <= new_srcGen;
      dma_write_server.writeData.put(ObjectData{data:{srcGen+1,srcGen}, tag: tagFifo.first});
   endrule
   
   rule wrDone;
      let new_respCnt = respCnt+extend(burstLen);
      if (new_respCnt >= reqLen) begin
	 new_respCnt = 0;
	 if (iterCnt == 0)
	    indication.writeDone(new_respCnt);
      end
      respCnt <= new_respCnt;
      let rv <- dma_write_server.writeDone.get;
   endrule

   method Action startWrite(Bit#(32) wp, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
      $display("startWrite pointer=%d numWords=%h burstLen=%d iterCnt=%d", wp, nw, bl, ic);
      indication.started(nw);
      wrPointer <= wp;
      reqLen    <= nw*4;
      burstLen  <= truncate(bl*4);
      respCnt   <= 0;
      wrOff     <= 0;
      iterCnt   <= ic;
   endmethod
   
   method Action getStateDbg();
      indication.reportStateDbg(0, srcGen);
   endmethod
   
endmodule