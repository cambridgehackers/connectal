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

import Vector::*;
import FIFOF::*;
import GetPutF::*;
import FIFO::*;

import PortalMemory::*;
import Dma::*;

interface MemcpyEngine;
   method Action startCopy(Bit#(32) wrPointer, Bit#(32) rdPointer, Bit#(32) numWords, Bit#(32) burstLen);
   method ActionValue#(Bool) done();
endinterface

module mkMemcpyEngine#(DmaReadServer#(busWidth) dma_read_server,
		       DmaWriteServer#(busWidth) dma_write_server)(MemcpyEngine)

   provisos (Div#(busWidth,8,busWidthBytes),
	     Add#(a__,64,busWidth),
	     Add#(b__,32,busWidth));

   let busWidthBytes = valueOf(busWidthBytes);
   let busWidthWords = busWidthBytes/4;

   Reg#(Bit#(32))         numWords <- mkReg(0);
   Reg#(Bit#(32))            rdCnt <- mkReg(0);
   Reg#(Bit#(32))            wrCnt <- mkReg(0);
   
   Reg#(Bit#(DmaOffsetSize)) rdOff <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) wrOff <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) delta <- mkReg(0);

   Reg#(DmaPointer)      rdPointer <- mkReg(0);
   Reg#(DmaPointer)      wrPointer <- mkReg(0);

   Reg#(Bit#(8))          burstLen <- mkReg(0);
   
   FIFO#(Bool)             ackFIFO <- mkSizedFIFO(32);
   FIFO#(void)            doneFIFO <- mkSizedFIFO(1);
   
   rule readReq (rdCnt < numWords>>1);
      //$display("rdReq: pointer=%d offset=%h burstlen=%d", rdPointer, rdOff, burstLen);
      rdCnt <= rdCnt+extend(burstLen);
      rdOff <= rdOff + delta;
      dma_read_server.readReq.put(DmaRequest {pointer: rdPointer, offset: rdOff, burstLen: extend(burstLen), tag: truncate(rdOff>>5)});
   endrule
   
   rule writeReq (wrCnt < numWords>>1);
      //$display("wrReq: pointer=%d offset=%h burstlen=%d", wrPointer, wrOff, burstLen);
      wrCnt <= wrCnt+extend(burstLen);
      wrOff <= wrOff + delta;
      dma_write_server.writeReq.put(DmaRequest {pointer: wrPointer, offset: wrOff, burstLen: extend(burstLen), tag: truncate(wrOff>>5)});
      ackFIFO.enq(wrCnt == (numWords>>1)-extend(burstLen));
   endrule
   
   rule writeAck;
      if (ackFIFO.first) begin
	 doneFIFO.enq(?);
      end
      let tag <- dma_write_server.writeDone.get();
      ackFIFO.deq;
   endrule
   
   rule loopback;
      let tagdata <- dma_read_server.readData.get();
      let v = tagdata.data;
      dma_write_server.writeData.put(tagdata);
      //$display("loopback %h", tagdata.data);
   endrule
   
   method Action startCopy(Bit#(32) wp, Bit#(32) rp, Bit#(32) nw, Bit#(32) bl);
      $display("startCopy wrPointer=%d rdPointer=%d numWords=%h burstLen=%d", wp, rp, nw, bl);
      // initialized
      wrPointer <= wp;
      rdPointer <= rp;
      numWords  <= nw;
      burstLen <= truncate(bl);
      delta <= 8*extend(bl);
      // reset
      rdCnt <= 0;
      wrCnt <= 0;
      rdOff <= 0;
      wrOff <= 0;
   endmethod

   method ActionValue#(Bool) done;
      doneFIFO.deq;
      return True;
   endmethod

endmodule
