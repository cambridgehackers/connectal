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
import ConnectalMemTypes::*;
import MemWriteEngine::*;
import ConnectalMemUtils::*;
import Pipe::*;

interface BRAMWriter#(numeric type bramIdxWidth, numeric type busWidth);
   method Action start(SGLId h, Bit#(MemOffsetSize) base, Bit#(bramIdxWidth) start_idx, Bit#(bramIdxWidth) finish_idx);
   method ActionValue#(Bool) finish();
endinterface
   
interface BRAMReadClient#(numeric type bramIdxWidth, numeric type busWidth);
   method Action start(SGLId h, Bit#(MemOffsetSize) base, Bit#(bramIdxWidth) start_idx, Bit#(bramIdxWidth) finish_idx);
   method ActionValue#(Bool) finish();
   interface MemReadClient#(busWidth) dmaClient;
endinterface

interface BRAMWriteClient#(numeric type bramIdxWidth, numeric type busWidth);
   method Action start(SGLId h, Bit#(MemOffsetSize) base, Bit#(bramIdxWidth) start_idx, Bit#(bramIdxWidth) finish_idx);
   method ActionValue#(Bool) finish();
   interface MemWriteClient#(busWidth) dmaClient;
endinterface

interface BRAMPipeIn#(numeric type bramIdxWidth, numeric type busWidth);
   interface PipeIn#(MemDataF#(busWidth)) pipe;
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
   Reg#(SGLId) ptr <- mkReg(0);
   Reg#(Bit#(MemOffsetSize)) off <- mkReg(0);
   Gearbox#(nd,1,d) gb <- mkNto1Gearbox(clk,rst,clk,rst); 
   
   let bus_width_in_bytes = fromInteger(valueOf(busWidth)/8);
   MemReader#(busWidth) re <- mkMemReader;
   
   rule feed_gearbox;
      let v <- re.readServer.readData.get;
      //$display("mkBRAMReadClient::readData.get %x", v.data);
      gb.enq(unpack(v.data));
   endrule
   
   rule loadReq(i <= n);
      re.readServer.readReq.put(MemRequest{sglId:ptr, offset:off, burstLen:bus_width_in_bytes, tag:0});
      off <= off+bus_width_in_bytes;
      //$display("mkBRAMReadClient::readReq.put %x, %x", i, n);
      i <= i+fromInteger(valueOf(nd));
   endrule
      
   rule load(j <= n);
      br.request.put(BRAMRequest{write:True, responseOnWrite:False, address:truncate(j), datain:gb.first[0]});
      gb.deq;
      j <= j+1;
      //$display("mkBRAMReadClient::bramserver put write %x, %x", j, n);
      if (j == n)
	 f.enq(?);
   endrule
   
   rule discard(j > n);
      gb.deq;
   endrule
   
   method Action start(SGLId h, Bit#(MemOffsetSize) b, Bit#(bramIdxWidth) start_idx, Bit#(bramIdxWidth) finish_idx);
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


module mkBRAMWriter#(Integer id,
		     BRAMServer#(Bit#(bramIdxWidth),d) br, 
		     MemReadEngineServer#(busWidth) readServer)(BRAMWriter#(bramIdxWidth,busWidth))
   provisos(Bits#(d,dsz),
	    Div#(busWidth,dsz,nd),
	    Mul#(nd,dsz,busWidth),
	    Add#(1,a__,nd),
	    Add#(1,bramIdxWidth,cntW),
	    Div#(busWidth,8,bwbytes),
	    Mul#(bwbytes, 8, busWidth),
	    Add#(b__, bramIdxWidth, 32),
	    Add#(c__, TLog#(nd), 32));

   let verbose = False;
   Clock clk <- exposeCurrentClock;
   Reset rst <- exposeCurrentReset;
   Reg#(Bit#(cntW)) j <- mkReg(maxBound);
   Reg#(Bit#(cntW)) n <- mkReg(0);
   Gearbox#(nd,1,d) gb <- mkNto1Gearbox(clk,rst,clk,rst);
   Reg#(Bool) running <- mkReg(False);
   FIFO#(void) doneFifo <- mkFIFO;
   
   rule feed_gearbox if (running);
      let v <- toGet(readServer.data).get;
      if(verbose) $display("mkBRAMWriter::feed_gearbox (%d) %x", id, v.data);
      gb.enq(unpack(v.data));
      if (v.last)
          doneFifo.enq(?);
   endrule
   
   rule load(j <= n);
      br.request.put(BRAMRequest{write:True, responseOnWrite:False, address:truncate(j), datain:gb.first[0]});
      gb.deq;
      j <= j+1;
      if(verbose) $display("mkBRAMWriter::load (%d) %x, %x", id, j, n);
   endrule
   
   rule discard(j > n);
      gb.deq;
      if(verbose) $display("mkBRAMWriter::discard (%d) %x", id, j);
   endrule

   method Action start(SGLId h, Bit#(MemOffsetSize) b, Bit#(bramIdxWidth) start_idx, Bit#(bramIdxWidth) finish_idx) if (!running);
      if(verbose) $display("mkBRAMWriter::start (%d) %d, %d, %d %d", id, h, b, start_idx, finish_idx);
      Bit#(BurstLenSize) burst_len_bytes = fromInteger(valueOf(bwbytes));

      Bit#(32) req_len_ds = extend(finish_idx-start_idx)+fromInteger(valueOf(nd));
      Bit#(TLog#(nd)) zeros = 0;
      Bit#(32) req_len_bytes = {zeros,req_len_ds[31:valueOf(TLog#(nd))]} * fromInteger(valueOf(bwbytes));

      readServer.request.put(MemengineCmd{sglId:h, base:truncate(b), len:req_len_bytes, burstLen:burst_len_bytes, tag: 0});
      if(verbose) $display("mkBRAMWriter::start id=%d offset=%d len=%d burstLen=%d", id, b, req_len_bytes, burst_len_bytes);
      j <= extend(start_idx);
      n <= extend(finish_idx);
      running <= True;
   endmethod

   method ActionValue#(Bool) finish() if (running);
      if(verbose) $display("mkBRAMWriter::finish (%d)", id);
      doneFifo.deq;
      running <= False;
      return True;
   endmethod
   
endmodule

module mkBRAMWriteClient#(BRAMServer#(Bit#(bramIdxWidth),d) br)(BRAMWriteClient#(bramIdxWidth,busWidth))
   provisos(Bits#(d,dsz),
	    Div#(busWidth,dsz,nd),
	    Mul#(nd,dsz,busWidth),
	    Add#(1,a__,nd),
	    Add#(1, d__, busWidth),
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
   Reg#(SGLId) ptr <- mkReg(0);
   Reg#(Bit#(MemOffsetSize)) off <- mkReg(0);
   Gearbox#(1,nd,Bit#(dsz)) gb <- mk1toNGearbox(clk,rst,clk,rst);
   
   MemWriteEngine#(busWidth,busWidth,1,1) we <- mkMemWriteEngine;
   Bit#(MemOffsetSize) bus_width_in_bytes = fromInteger(valueOf(busWidth)/8);
      
   rule drain_geatbox;
      Vector#(nd,Bit#(dsz)) v = gb.first;
      we.writeServers[0].data.enq(pack(v));
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
      we.writeServers[0].request.put(MemengineCmd{sglId:ptr, base:truncate(off), len:truncate(bus_width_in_bytes), burstLen:truncate(bus_width_in_bytes), tag: 0});
      off <= off+bus_width_in_bytes;
      i <= i+fromInteger(valueOf(nd));
      //$display("mkBRAMWriteClient::loadReq %h", i);
   endrule
   
   rule loadResp;
      let __x <- we.writeServers[0].done.get;
      if (i > n)
	 f.enq(?);
   endrule
   
   method Action start(SGLId h, Bit#(MemOffsetSize) b, Bit#(bramIdxWidth) start_idx, Bit#(bramIdxWidth) finish_idx);
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

module mkBRAMPipeIn#(Integer id,
		     BRAMServer#(Bit#(bramIdxWidth),d) br)(BRAMPipeIn#(bramIdxWidth,busWidth))
   provisos(Bits#(d,dsz),
	    Div#(busWidth,dsz,nd),
	    Mul#(nd,dsz,busWidth),
	    Add#(1,a__,nd),
	    Add#(1,bramIdxWidth,cntW),
	    Div#(busWidth,8,bwbytes),
	    Mul#(bwbytes, 8, busWidth),
	    Add#(b__, bramIdxWidth, 32),
	    Add#(c__, TLog#(nd), 32));

   let verbose = False;
   Clock clk <- exposeCurrentClock;
   Reset rst <- exposeCurrentReset;
   Reg#(Bit#(cntW)) j <- mkReg(0);
   Reg#(Bit#(cntW)) n <- mkReg(0);
   Gearbox#(nd,1,MemDataF#(dsz)) gb <- mkNto1Gearbox(clk,rst,clk,rst);
   Reg#(Bool) running <- mkReg(False);
   FIFO#(void) doneFifo <- mkFIFO;
   FIFOF#(MemDataF#(busWidth)) dataFifo <- mkFIFOF();
   
   rule feed_gearbox;
      let md <- toGet(dataFifo).get;
      if(verbose) $display("mkBRAMWriter::feed_gearbox (%d) %x", id, md.data);
      Vector#(nd,Bit#(dsz)) ds = unpack(md.data);
      Vector#(nd,MemDataF#(dsz)) mds = unpack(0);
      for (Integer i = 0; i < valueOf(nd); i = i + 1)
	 mds[i].data = ds[i];
      if (md.last)
	 mds[valueOf(nd)-1].last = True;
      gb.enq(mds);
   endrule
   
   rule load;
      let md = gb.first[0];
      $display("load id=%d j=%d data=%h", id, j, md.data);
      br.request.put(BRAMRequest{write:True, responseOnWrite:False, address:truncate(j), datain:unpack(md.data)});
      gb.deq;
      let nextj = j + 1;
      if (md.last) begin
	 nextj = 0;
	 $display("end of stream j=%d", j);
	 end
      j <= nextj;
      if(verbose) $display("mkBRAMWriter::load (%d) %x, %x", id, j, n);
   endrule
   
   interface PipeIn pipe = toPipeIn(dataFifo);

endmodule
