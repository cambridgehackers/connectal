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
import SpecialFIFOs::*;
import Vector::*;
import BRAM::*;
import Gearbox::*;

import AxiMasterSlave::*;
import MemTypes::*;
import MPEngine::*;
import MemreadEngine::*;
import Pipe::*;

interface StrstrRequest;
   method Action setup(Bit#(32) needlePointer, Bit#(32) mpNextPointer, Bit#(32) needle_len);
   method Action search(Bit#(32) haystackPointer, Bit#(32) haystack_len, Bit#(32) iter_cnt);
endinterface

interface StrstrIndication;
   method Action searchResult(Int#(32) v);
   method Action setupComplete();
endinterface

interface Strstr#(numeric type p, numeric type busWidth);
   interface StrstrRequest request;
   interface ObjectReadClient#(busWidth) config_read_client;
   interface ObjectReadClient#(busWidth) haystack_read_client;
endinterface

module mkStrstr#(StrstrIndication indication)(Strstr#(p,busWidth))
   provisos(Add#(a__, 8, busWidth),
	    Div#(busWidth,8,nc),
	    Mul#(nc,8,busWidth),
	    Add#(1, b__, nc),
	    Add#(c__, 32, busWidth),
	    Add#(1, d__, TDiv#(busWidth, 32)),
	    Mul#(TDiv#(busWidth, 32), 32, busWidth),
	    Log#(p,lp),
	    Add#(e__, TLog#(nc), 32),
	    Add#(f__, TLog#(TDiv#(busWidth, 32)), 32)
	    
	    // these were added for the readengines
	    ,Add#(k__, TLog#(TMul#(p, 2)), TLog#(TMul#(1, TMul#(p, 2))))
	    ,Pipe::FunnelPipesPipelined#(1, TMul#(p, 2), Tuple2#(Bit#(busWidth), Bool),TMin#(2, TLog#(TMul#(p, 2))))
	    ,Pipe::FunnelPipesPipelined#(1, TMul#(p, 2), Tuple2#(Bit#(TLog#(TMul#(p,2))), MemTypes::MemengineCmd), TMin#(2, TLog#(TMul#(p, 2))))
	    ,Add#(l__, TLog#(TMul#(p, 2)), TAdd#(1, TLog#(TMul#(1, TMul#(p, 2)))))
	    ,Add#(1, m__, TMul#(p, 2))
	    ,Add#(n__, TLog#(TMul#(p, 1)), TLog#(TMul#(1, TMul#(p, 1))))
	    ,Pipe::FunnelPipesPipelined#(1, TMul#(p, 1), Tuple2#(Bit#(busWidth), Bool),TMin#(2, TLog#(TMul#(p, 1))))
	    ,Pipe::FunnelPipesPipelined#(1, TMul#(p, 1), Tuple2#(Bit#(TLog#(TMul#(p,1))), MemTypes::MemengineCmd), TMin#(2, TLog#(TMul#(p, 1))))
	    ,Add#(o__, TLog#(TMul#(p, 1)), TAdd#(1, TLog#(TMul#(1, TMul#(p, 1)))))
	    ,Add#(1, p__, TMul#(p, 1))
	    ,Add#(2, q__, TMul#(p, 2))

	    );
   

   let verbose = False;

   Reg#(Bit#(32)) needleLen <- mkReg(0);
   MemreadEngineV#(busWidth, 1, TMul#(p,2)) config_re <- mkMemreadEngine;
   MemreadEngineV#(busWidth, 1, TMul#(p,1)) haystack_re <- mkMemreadEngine;

   Reg#(Bit#(32)) iterCnt <- mkReg(0);
   Reg#(Bit#(32)) haystackPointer <- mkReg(0);
   Reg#(Bit#(32)) haystackLen <- mkReg(0);
   FIFO#(void) restartf <- mkSizedFIFO(1);
	       
   Vector#(p, MPEngine#(busWidth)) engines;
   for(Integer i = 0; i < valueOf(p); i=i+1) begin 
      let config_rss = takeAt(i*2, config_re.read_servers);
      let haystack_rs = haystack_re.read_servers[i];
      engines[i] <- mkMPEngine(cons(haystack_rs,config_rss));
   end
   
   rule confr;
      for(Integer i = 0; i < valueOf(p); i=i+1) 
	 let rv <- engines[i].finishSetup;
      indication.setupComplete;
   endrule
   
   for(Integer i = 0; i < valueOf(p); i=i+1)
      rule resr;
	 let rv <- engines[i].loc.get;
	 indication.searchResult(rv);
	 if (verbose) $display("strstr search result %d", rv);
      endrule
   
   rule restartr(iterCnt > 0);
      if (verbose) $display("restartr %d", iterCnt);
      restartf.deq;
      iterCnt <= iterCnt-1;
      let pv = fromInteger(valueOf(p));
      let lpv = fromInteger(valueOf(lp));
      Bit#(32) base = 0;
      for(Integer i = 0; i < valueOf(p)-1; i=i+1) begin
	 engines[fromInteger(i)].search(haystackPointer, (haystackLen>>lpv)+needleLen, base);
	 base = base + (haystackLen>>lpv);
      end
      engines[pv-1].search(haystackPointer, haystackLen>>lpv, base);
   endrule
   
   rule compr;
      for(Integer i = 0; i < valueOf(p); i=i+1)
	 let rv <- engines[i].finishSearch;
      if (verbose) $display("strstr iterCnt %x\n", iterCnt);
      if(iterCnt==0)
	 indication.searchResult(-1);
      else
	 restartf.enq(?);
   endrule
   
   interface StrstrRequest request;
      method Action setup(Bit#(32) needle_pointer, Bit#(32) mpNext_pointer, Bit#(32) needle_len);
	 if (verbose) $display("mkStrstr::setup %d %d %d", needle_pointer, mpNext_pointer, needle_len);
	 needleLen <= needle_len;
	 for(Integer i = 0; i < valueOf(p); i=i+1)
	    engines[fromInteger(i)].setup(needle_pointer, mpNext_pointer, needle_len);
      endmethod
   
      method Action search(Bit#(32) haystack_pointer, Bit#(32) haystack_len, Bit#(32) iter_cnt);
	 if (verbose) $display("mkStrstr::search %d %d %d", haystack_pointer, haystack_len, iter_cnt);
	 haystackLen <= haystack_len;
	 haystackPointer <= haystack_pointer;
	 iterCnt <= iter_cnt;
	 restartf.enq(?);
	 $dumpvars();
      endmethod
   endinterface
   interface config_read_client = config_re.dmaClient;
   interface haystack_read_client = haystack_re.dmaClient;
endmodule


