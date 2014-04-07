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
import FIFO::*;
import Connectable::*;
import GetPut::*;

import PortalMemory::*;
import Dma::*;


interface MemcpyRequest;
   method Action startCopy(Bit#(32) wrPointer, Bit#(32) rdPointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
endinterface

interface MemcpyIndication;
   method Action started;
   method Action done;
endinterface

module mkMemcpyRequest#(MemcpyIndication indication,
			ObjectReadServer#(64) dma_read_server,
			ObjectWriteServer#(64) dma_write_server)(MemcpyRequest);

   Reg#(ObjectPointer)       rdPointer <- mkReg(0);
   Reg#(ObjectPointer)       wrPointer <- mkReg(0);
   Reg#(Bit#(8))              burstLen <- mkReg(0);
   Reg#(Bit#(32))               reqLen <- mkReg(0);

   Reg#(Bit#(32))            wrRespCnt <- mkReg(0);
   Reg#(Bit#(32))                wrOff <- mkReg(0);
   FIFO#(Bool)                    wrFF <- mkSizedFIFO(1);
   Reg#(Bit#(6))                 wrTag <- mkReg(0);

   Reg#(Bit#(32))            rdRespCnt <- mkReg(0);
   Reg#(Bit#(32))                rdOff <- mkReg(0);
   FIFO#(Bool)                    rdFF <- mkSizedFIFO(1);
   Reg#(Bit#(6))                 rdTag <- mkReg(0);
   
   FIFO#(ObjectData#(64))            f <- mkFIFO;
   
   rule finish;
      rdFF.deq;
      wrFF.deq;
      indication.done;
   endrule
   
   rule rdReq if (rdOff < reqLen);
      rdOff <= rdOff + extend(burstLen);
      dma_read_server.readReq.put(ObjectRequest { pointer: rdPointer, offset: extend(rdOff), burstLen: burstLen, tag: rdTag });
      rdTag <= rdTag+1;
      //$display("rdReq %h %h", rdOff, burstLen);
   endrule
   
   rule rdData;
      ObjectData#(64) d <- dma_read_server.readData.get;
      if (rdRespCnt+(64/8) >= reqLen)
	 rdFF.enq(True);
      rdRespCnt <= rdRespCnt+(64/8);
      f.enq(d);
      //$display("rdData %h", rdRespCnt);
   endrule

   rule wrReq if (wrOff < reqLen);
      wrOff <= wrOff + extend(burstLen);
      dma_write_server.writeReq.put(ObjectRequest { pointer: wrPointer, offset: extend(wrOff), burstLen: burstLen, tag: wrTag });
      wrTag <= wrTag+1;
      //$display("wrReq %h %h", wrOff, reqLen);
   endrule

   rule wrData;
      f.deq;
      dma_write_server.writeData.put(ObjectData{data:f.first.data, tag: 0});
      //$display("wrData");
   endrule
   
   rule wrDone;
      let rv <- dma_write_server.writeDone.get;
      if (wrRespCnt+extend(burstLen) >= reqLen)
   	 wrFF.enq(True);
      wrRespCnt <= wrRespCnt+extend(burstLen);
      //$display("wrDone %h", wrRespCnt);
   endrule
   
   method Action startCopy(Bit#(32) wp, Bit#(32) rp, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
      $display("startCopy wrPointer=%d rdPointer=%d numWords=%h burstLen=%d iterCnt=%d", wp, rp, nw, bl, ic);
      indication.started;
      wrPointer <= wp;
      rdPointer <= rp;
      reqLen    <= nw*4;
      burstLen  <= truncate(bl*4);
      wrRespCnt <= 0;
      wrOff     <= 0;
      rdRespCnt <= 0;
      rdOff     <= 0;
   endmethod

endmodule
