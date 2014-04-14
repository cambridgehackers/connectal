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
import GetPut::*;

import Dma::*;
import MemreadEngine::*;

interface MemreadRequest;
   method Action startRead(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
   method Action getStateDbg();   
endinterface

interface MemreadIndication;
   method Action started(Bit#(32) numWords);
   method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) mismatchCount);
   method Action readDone(Bit#(32) mismatchCount);
endinterface

module mkMemread#(MemreadIndication indication,
		  ObjectReadServer#(64) dma_read_server)(MemreadRequest);
   
   Reg#(ObjectPointer)     rdPointer <- mkReg(0);
   Reg#(Bit#(8))            burstLen <- mkReg(0);
   Reg#(Bit#(32))             reqLen <- mkReg(0);

   Reg#(Bit#(3))               rdTag <- mkReg(0);
   Reg#(Bit#(32))            respCnt <- mkReg(0);
   Reg#(Bit#(32))              rdOff <- mkReg(0);
   Reg#(Bit#(32))            iterCnt <- mkReg(0);
         
   rule rdReq if (rdOff < reqLen);
      let new_rdOff = rdOff + extend(burstLen);
      dma_read_server.readReq.put(ObjectRequest { pointer: rdPointer, offset: extend(rdOff), burstLen: burstLen, tag: extend(rdTag) });
      if (new_rdOff >= reqLen) begin
	 if (iterCnt > 1) 
	    new_rdOff = 0;
	 iterCnt <= iterCnt-1;
      end
      rdOff <= new_rdOff;
      rdTag <= rdTag+1;
   endrule
   
   rule rdData;
      let new_respCnt = respCnt+(64/8);
      if (new_respCnt >= reqLen) begin
	 new_respCnt = 0;
	 if (iterCnt == 0)
	    indication.readDone(0);
      end
      ObjectData#(64) d <- dma_read_server.readData.get;
      respCnt <= new_respCnt;
   endrule
     
   method Action startRead(Bit#(32) rp, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
      $display("startRead rdPointer=%d numWords=%h burstLen=%d iterCnt=%d", rp, nw, bl, ic);
      indication.started(nw);
      rdPointer <= rp;
      burstLen  <= truncate(bl*4);
      reqLen    <= nw*4;
      respCnt   <= 0;
      rdOff     <= 0;
      iterCnt   <= ic;
   endmethod
   
   method Action getStateDbg();
      indication.reportStateDbg(0, 0);
   endmethod
   
endmodule


