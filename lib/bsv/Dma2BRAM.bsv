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
import GetPut::*;
import ClientServer::*;

import BRAMFIFOFLevel::*;
import MemTypes::*;
import MemwriteEngine::*;
import MemUtils::*;
import Pipe::*;

interface BRAMReadClient#(numeric type bramIdxWidth, numeric type busWidth);
   method Action start(ObjectPointer h, Bit#(ObjectOffsetSize) base, Bit#(bramIdxWidth) start_idx, Bit#(bramIdxWidth) finish_idx);
   method ActionValue#(Bool) finish();
   interface ObjectReadClient#(busWidth) dmaClient;
endinterface

interface BRAMWriteClient#(numeric type bramIdxWidth, numeric type busWidth);
   method Action start(ObjectPointer h, Bit#(ObjectOffsetSize) base, Bit#(bramIdxWidth) start_idx, Bit#(bramIdxWidth) finish_idx);
   method ActionValue#(Bool) finish();
   interface ObjectWriteClient#(busWidth) dmaClient;
endinterface

module mkBRAMReadClient#(BRAMServer#(Bit#(bramIdxWidth),d) br)(BRAMReadClient#(bramIdxWidth,busWidth))
   provisos(Bits#(d,dsz),
	    Div#(busWidth,dsz,nd),
	    Mul#(nd,dsz,busWidth),
	    Add#(1,a__,nd),
	    Add#(1,bramIdxWidth,cntW),
	    Mul#(TDiv#(busWidth, 8), 8, busWidth));
   
   Clock clk <- exposeCurrentClock;
   Reset rst <- exposeCurrentReset;
   FIFO#(void) f <- mkSizedFIFO(1);
   Reg#(Bit#(cntW)) i <- mkReg(maxBound);
   Reg#(Bit#(cntW)) j <- mkReg(maxBound);
   Reg#(Bit#(cntW)) n <- mkReg(0);
   Reg#(ObjectPointer) ptr <- mkReg(0);
   Reg#(Bit#(ObjectOffsetSize)) off <- mkReg(0);
   Gearbox#(nd,1,d) gb <- mkNto1Gearbox(clk,rst,clk,rst); 
   
   let bus_width_in_bytes = fromInteger(valueOf(busWidth)/8);
   MemReader#(busWidth) re <- mkMemReader;
   
   rule feed_gearbox;
      let v <- re.readServer.readData.get;
      gb.enq(unpack(v.data));
   endrule
   
   rule loadReq(i <= n);
      re.readServer.readReq.put(ObjectRequest{pointer:ptr, offset:off, burstLen:bus_width_in_bytes, tag:0});
      off <= off+bus_width_in_bytes;
      i <= i+fromInteger(valueOf(nd));
   endrule
      
   rule load(j <= n);
      br.request.put(BRAMRequest{write:True, responseOnWrite:False, address:truncate(j), datain:gb.first[0]});
      gb.deq;
      j <= j+1;
      if (j == n)
	 f.enq(?);
   endrule
   
   rule discard(j > n);
      gb.deq;
   endrule
   
   method Action start(ObjectPointer h, Bit#(ObjectOffsetSize) b, Bit#(bramIdxWidth) start_idx, Bit#(bramIdxWidth) finish_idx);
      $display("mkBRAMReadClient::start(%h, %h, %h %h)", h, b, start_idx, finish_idx);
      i <= extend(start_idx);
      j <= extend(start_idx);
      n <= extend(finish_idx);
      ptr <= h;
      off <= b;
   endmethod
   
   method ActionValue#(Bool) finish();
      $display("mkBRAMReadClient::finish");
      f.deq;
      return True;
   endmethod
   
   interface dmaClient = re.readClient;

endmodule

module mkBRAMWriteClient#(BRAMServer#(Bit#(bramIdxWidth),d) br)(BRAMWriteClient#(bramIdxWidth,busWidth))
   provisos(Bits#(d,dsz),
	    Div#(busWidth,dsz,nd),
	    Mul#(nd,dsz,busWidth),
	    Add#(1,a__,nd),
	    Add#(1, b__, TMul#(2, nd)),
	    Add#(nd, c__, TMul#(2, nd)),
	    Add#(1,bramIdxWidth,cntW),
	    Mul#(TDiv#(busWidth, 8), 8, busWidth));
   
   Clock clk <- exposeCurrentClock;
   Reset rst <- exposeCurrentReset;
   FIFO#(void) f <- mkSizedFIFO(1);
   Reg#(Bit#(cntW)) i <- mkReg(maxBound);
   Reg#(Bit#(cntW)) j <- mkReg(maxBound);
   Reg#(Bit#(cntW)) n <- mkReg(0);
   Reg#(ObjectPointer) ptr <- mkReg(0);
   Reg#(Bit#(ObjectOffsetSize)) off <- mkReg(0);
   Gearbox#(1,nd,Bit#(dsz)) gb <- mk1toNGearbox(clk,rst,clk,rst);
   
   MemwriteEngine#(busWidth,1) we <- mkMemwriteEngine;
   Bit#(ObjectOffsetSize) bus_width_in_bytes = fromInteger(valueOf(busWidth)/8);
      
   rule drain_geatbox;
      Vector#(nd,Bit#(dsz)) v = gb.first;
      we.dataPipes[0].enq(pack(v));
      gb.deq;
   endrule
   
   rule bramReq(j <= n);
      //$display("mkBRAMWriteClient::bramReq %h", j);
      br.request.put(BRAMRequest{write:False, responseOnWrite:False, address:truncate(j), datain:?});
      j <= j+1;
   endrule

   rule bramResp;
      d rv <- br.response.get;
      gb.enq(cons(pack(rv), nil));
   endrule
   
   rule loadReq(i <= n);
      we.writeServers[0].request.put(MemengineCmd{pointer:ptr, base:off, len:truncate(bus_width_in_bytes), burstLen:truncate(bus_width_in_bytes)});
      off <= off+bus_width_in_bytes;
      i <= i+fromInteger(valueOf(nd));
      //$display("mkBRAMWriteClient::loadReq %h", i);
   endrule
   
   rule loadResp;
      let __x <- we.writeServers[0].response.get;
      if (i > n)
	 f.enq(?);
   endrule
   
   method Action start(ObjectPointer h, Bit#(ObjectOffsetSize) b, Bit#(bramIdxWidth) start_idx, Bit#(bramIdxWidth) finish_idx);
      $display("mkBRAMWriteClient::start(%h, %h, %h %h)", h, b, start_idx, finish_idx);
      i <= extend(start_idx);
      j <= extend(start_idx);
      n <= extend(finish_idx);
      ptr <= h;
      off <= b;
   endmethod
   
   method ActionValue#(Bool) finish();
      $display("mkBRAMWriteClient::finish");
      f.deq;
      return True;
   endmethod
   
   interface dmaClient = we.dmaClient;

endmodule

