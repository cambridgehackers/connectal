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


import BRAM::*;
import FIFO::*;
import Vector::*;
import Gearbox::*;
import FIFOF::*;
import SpecialFIFOs::*;

import BRAMFIFOFLevel::*;
import GetPutF::*;
import Dma::*;
import MemreadEngine::*;
import MemwriteEngine::*;

interface BRAMReadClient#(type bramIdx, numeric type busWidth);
   method Action start(DmaPointer h, Bit#(DmaOffsetSize) rbase, bramIdx num, bramIdx wbase);
   method ActionValue#(Bool) finish();
   interface DmaReadClient#(busWidth) dmaClient;
endinterface

interface BRAMWriteClient#(type bramIdx, numeric type busWidth);
   method Action start(DmaPointer h, Bit#(DmaOffsetSize) rbase, bramIdx num, bramIdx wbase);
   method ActionValue#(Bool) finish();
   interface DmaWriteClient#(busWidth) dmaClient;
endinterface

module mkBRAMReadClient#(BRAMServer#(bramIdx,d) br)(BRAMReadClient#(bramIdx,busWidth))
   provisos(Bits#(d,dsz),
	    Div#(busWidth,dsz,nd),
	    Mul#(nd,dsz,busWidth),
	    Add#(1,a__,nd),
	    Eq#(bramIdx),
	    Ord#(bramIdx),
	    Arith#(bramIdx),
	    Bits#(bramIdx,b__));
   
   Clock clk <- exposeCurrentClock;
   Reset rst <- exposeCurrentReset;
   
   FIFO#(void) f <- mkSizedFIFO(1);
   Gearbox#(nd,1,d) gb <- mkNto1Gearbox(clk,rst,clk,rst); 
   Reg#(bramIdx) i <- mkReg(0);
   Reg#(bramIdx) j <- mkReg(0);
   Reg#(bramIdx) n <- mkReg(0);
   Reg#(bramIdx) wbase <- mkReg(0);
   Reg#(DmaPointer) ptr <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) roff <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) rbase <- mkReg(0);
   
   let readFifo <- mkFIFOF;
   MemreadEngine#(busWidth) re <- mkMemreadEngine(readFifo);
   let bus_width_in_bytes = fromInteger(valueOf(busWidth)/8);
   
   rule loadReq(i < n);
      //$display("mkBRAMReadClient::loadReq ptr=%d %d %d", ptr, roff+rbase, bus_width_in_bytes);
      re.start(ptr, roff + rbase, bus_width_in_bytes, bus_width_in_bytes);
      i <= i+fromInteger(valueOf(nd));
      roff <= roff+bus_width_in_bytes;
   endrule
   
   rule loadResp;
      let __x <- re.finish;
      readFifo.deq;
      let rv = readFifo.first;
      Vector#(nd,d) rvv = unpack(rv);
      gb.enq(rvv);
      //$display("mkBRAMReadClient::loadResp ptr=%d", ptr);
   endrule
   
   rule load(j < n);
      br.request.put(BRAMRequest{write:True, responseOnWrite:False, address:j+wbase, datain:gb.first[0]});
      gb.deq;
      j <= j+1;
      if (j+1 == n)
	 f.enq(?);
      //$display("mkBRAMReadClient::load ptr=%d", ptr);
   endrule
   
   rule discard(j >= n);
      gb.deq;
      //$display("mkBRAMReadClient::discard ptr=%d", ptr);
   endrule
   
   method Action start(DmaPointer h, Bit#(DmaOffsetSize) rb, bramIdx num, bramIdx wb);
      $display("mkBRAMReadClient::start(%h, %h, %h %h)", h, wb, num, rb);
      i <= 0;
      j <= 0;
      n <= num;
      ptr <= h;
      roff <= 0;
      rbase <= rb;
      wbase <= wb;
   endmethod
   
   method ActionValue#(Bool) finish();
      f.deq;
      return True;
   endmethod
   
   interface dmaClient = re.dmaClient;

endmodule

module mkBRAMWriteClient#(BRAMServer#(bramIdx,d) br)(BRAMWriteClient#(bramIdx,busWidth))
   
   provisos(Bits#(d,dsz),
	    Div#(busWidth,dsz,nd),
	    Mul#(nd,dsz,busWidth),
	    Add#(1,a__,nd),
	    Add#(1, b__, TMul#(2, nd)),
	    Add#(nd, c__, TMul#(2, nd)),
	    Eq#(bramIdx),
	    Bits#(bramIdx, d__),
	    Ord#(bramIdx),
	    Arith#(bramIdx));

   Clock clk <- exposeCurrentClock;
   Reset rst <- exposeCurrentReset;

   FIFO#(void) f <- mkSizedFIFO(1);
   Reg#(bramIdx) n <- mkReg(0);
   Reg#(bramIdx) i <- mkReg(0);
   Reg#(bramIdx) j <- mkReg(0);
   Reg#(bramIdx) rbase <- mkReg(0);
   Reg#(DmaPointer) ptr <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) woff <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) wbase <- mkReg(0);
   Gearbox#(1,nd,Bit#(dsz)) gb <- mk1toNGearbox(clk,rst,clk,rst);
   
   FIFOF#(Bit#(busWidth)) writeFifo = (interface FIFOF;
				       method Bit#(busWidth) first(); return pack(gb.first); endmethod
				       method Bool notEmpty(); return gb.notEmpty(); endmethod
				       method Action enq(Bit#(busWidth) d); endmethod
				       method Action deq; endmethod
				       method Action clear; endmethod
				       method Bool notFull(); return(False); endmethod
      
				       endinterface);
   MemwriteEngine#(busWidth) we <- mkMemwriteEngine(writeFifo);
   let bus_width_in_bytes = fromInteger(valueOf(busWidth)/8);
   
   rule bramReq(j < n);
      br.request.put(BRAMRequest{write:False, responseOnWrite:False, address:j+rbase, datain:?});
      j <= j+1;
   endrule

   rule bramResp;
      d rv <- br.response.get;
      gb.enq(cons(pack(rv), nil));
   endrule
   
   rule loadReq(i < n);
      we.start(ptr, woff + wbase, bus_width_in_bytes, bus_width_in_bytes);
      i <= i+1;
      woff <= woff+bus_width_in_bytes;
   endrule
   
   rule loadResp;
      let __x <- we.finish;
      if (i == n)
	 f.enq(?);
   endrule
   
   method Action start(DmaPointer h, Bit#(DmaOffsetSize) wb, bramIdx num, bramIdx rb);
      //$display("mkBRAMWriteClient::start(%h, %h, %h %h)", h, wb, num, rb);
      i <= 0;
      j <= 0;
      n <= num;
      ptr <= h;
      rbase <= rb;
      wbase <= wb;
      woff <= 0;
   endmethod
   
   method ActionValue#(Bool) finish();
      f.deq;
      return True;
   endmethod
   
   interface dmaClient = we.dmaClient;

endmodule

