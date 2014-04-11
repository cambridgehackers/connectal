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
      
   rule wrData if (wrOff < reqLen);
      let new_burstCnt = burstCnt+(64/8);
      if (burstCnt == 0) begin
	 dma_write_server.writeReq.put(ObjectRequest { pointer: wrPointer, offset: extend(wrOff), burstLen: burstLen, tag: wrTag});
      end
      if (new_burstCnt == extend(burstLen)) begin 
	 burstCnt <= 0;
	 wrTag <= wrTag+1;
	 wrOff <= wrOff+extend(burstLen);
      end
      else 
	 burstCnt <= new_burstCnt;
      srcGen <= srcGen+2;
      dma_write_server.writeData.put(ObjectData{data:{srcGen+1,srcGen}, tag: wrTag});
   endrule
   
   rule wrDone;
      let new_respCnt = respCnt+extend(burstLen);
      respCnt <= new_respCnt;
      if (new_respCnt >= reqLen)
	 indication.writeDone(0);
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
   endmethod
   
   method Action getStateDbg();
      indication.reportStateDbg(0, srcGen);
   endmethod
   
endmodule