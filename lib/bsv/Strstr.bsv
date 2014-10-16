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
import Connectable::*;
import StmtFSM::*;

import AxiMasterSlave::*;
import MemTypes::*;
import MPEngine::*;
import MemreadEngine::*;
import Pipe::*;

interface StrstrRequest;
   method Action setup(Bit#(32) needleSGLId, Bit#(32) mpNextSGLId, Bit#(32) needle_len);
   method Action search(Bit#(32) haystackSGLId, Bit#(32) haystack_len, Bit#(32) iter_cnt);
endinterface

interface StrstrIndication;
   method Action searchResult(Int#(32) v);
endinterface

interface Strstr#(numeric type p, numeric type busWidth);
   interface StrstrRequest request;
   interface ObjectReadClient#(busWidth) config_read_client;
   interface ObjectReadClient#(busWidth) haystack_read_client;
endinterface

// I can't belive we still have to do this shit
function Bool my_or(Bool a, Bool b) = a || b;

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
	    Add#(f__, TLog#(TDiv#(busWidth, 32)), 32),
	    ReducePipe#(p, Bool),
	    FunnelPipesPipelined#(1, p, Tuple3#(Bit#(32), Bit#(32), Bit#(32)),2) 
	    
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
   
   let verbose = True;

   Reg#(Bit#(32)) needleLen <- mkReg(0);
   MemreadEngineV#(busWidth, 1, TMul#(p,2)) config_re <- mkMemreadEngine;
   MemreadEngineV#(busWidth, 1, TMul#(p,1)) haystack_re <- mkMemreadEngine;
   
   Reg#(Bit#(32)) iterCnt <- mkReg(0);
   Reg#(Bit#(32)) needleSGLId <- mkReg(0);
   Reg#(Bit#(32)) mpNextSGLId <- mkReg(0);
   Reg#(Bit#(32)) haystackSGLId <- mkReg(0);
   Reg#(Bit#(32)) haystackLen <- mkReg(0);
   FIFO#(void) restartf <- mkSizedFIFO(1);
   Reg#(Bit#(32)) restartCnt <- mkReg(0);
   Reg#(Bit#(32)) restartBase <- mkReg(0);
   Reg#(Bit#(32)) setupCnt <- mkReg(0);
	       
   Vector#(p, MPEngine#(busWidth)) engines;
   Vector#(p, PipeOut#(Bool)) donePipes;
   Vector#(p, PipeOut#(Int#(32))) locPipes;

   FIFO#(Tripple#(Bit#(32))) searchFIFO <- mkFIFO;
   PipeOut#(Tripple#(Bit#(32))) sp0 <- mkPipeOut(toGet(searchFIFO));
   UnFunnelPipe#(1,p,Tripple#(Bit#(32)),2) searchPipeUnFunnel <- mkUnFunnelPipesPipelinedRR(cons(sp0,nil), 1);

   FIFO#(Tripple#(Bit#(32))) setupFIFO <- mkFIFO;
   PipeOut#(Tripple#(Bit#(32))) sp1 <- mkPipeOut(toGet(setupFIFO));
   UnFunnelPipe#(1,p,Tripple#(Bit#(32)),2) setupPipeUnFunnel <- mkUnFunnelPipesPipelinedRR(cons(sp1,nil), 1);

   for(Integer i = 0; i < valueOf(p); i=i+1) begin 
      let config_rss = takeAt(i*2, config_re.read_servers);
      let haystack_rs = haystack_re.read_servers[i];
      engines[i] <- mkMPEngine(cons(haystack_rs,config_rss));
      donePipes[i] = engines[i].done;
      locPipes[i] = engines[i].loc;
      mkConnection(searchPipeUnFunnel[i],engines[i].search);
      mkConnection(setupPipeUnFunnel[i],engines[i].setup);
   end

   PipeOut#(Bool) donePipe <- mkReducePipes(uncurry(my_or), donePipes);
   PipeOut#(Int#(32)) locPipe <- mkFunnelPipes1(locPipes);

   // send results back to SW
   rule resr;
      let rv <- toGet(locPipe).get;
      indication.searchResult(rv);
      if (verbose) $display("strstr search result %d", rv);
   endrule
   
   // restart the search 'iterCnt' times
   let lpv = fromInteger(valueOf(lp));
   let pv = fromInteger(valueOf(p));
   Stmt restartStmt = 
   seq
      while(True) seq
	 action
	    if (verbose) $display("restartStmt (begin) %d", iterCnt);
	    restartf.deq;
	    iterCnt <= iterCnt-1;
	    restartCnt <= 0;
	    restartBase <= 0;
	 endaction
	 while (restartCnt < pv-1) action
	    let tup = tuple3(haystackSGLId, (haystackLen>>lpv)+needleLen, restartBase);
	    searchFIFO.enq(tup);
	    restartBase <= restartBase + (haystackLen>>lpv);
	    restartCnt <= restartCnt+1;
	    if (verbose) $display(fshow("restartStmt ")+fshow(tup)+fshow(" (mid)"));
	 endaction
	 action
	    let tup = tuple3(haystackSGLId, haystackLen>>lpv, restartBase);
	    searchFIFO.enq(tup);
	    if (verbose) $display(fshow("restartStmt ")+fshow(tup)+fshow(" (end)"));
	 endaction
      endseq
   endseq;
   mkAutoFSM(restartStmt);
   
   // notify the SW when the search is finished
   rule compr;
      donePipe.deq;
      if (verbose) $display("strstr iterCnt %x", iterCnt);
      if(iterCnt==0) indication.searchResult(-1);
      else restartf.enq(?);
   endrule
   
   // setup the MPEngines when new configuration arrives
   Stmt setupStmt = 
   seq
      action
	 if (verbose) $display("setupStmt (begin)");
	 setupCnt <= 0;
      endaction
      while(setupCnt < pv) action
	 setupCnt <= setupCnt+1;
	 setupFIFO.enq(tuple3(needleSGLId, mpNextSGLId, needleLen));
      endaction
      if (verbose) $display("setupStmt (end)");
   endseq;
   FSM setupFSM <- mkFSM(setupStmt);
   
   interface StrstrRequest request;
      method Action setup(Bit#(32) needle_sglId, Bit#(32) mpNext_sglId, Bit#(32) needle_len);
	 if (verbose) $display("mkStrstr::setup %d %d %d", needle_sglId, mpNext_sglId, needle_len);
	 needleLen <= needle_len;
	 needleSGLId <= needle_sglId;
	 mpNextSGLId <= mpNext_sglId;
	 setupFSM.start();
      endmethod
   
      method Action search(Bit#(32) haystack_sglId, Bit#(32) haystack_len, Bit#(32) iter_cnt);
	 if (verbose) $display("mkStrstr::search %d %d %d", haystack_sglId, haystack_len, iter_cnt);
	 haystackLen <= haystack_len;
	 haystackSGLId <= haystack_sglId;
	 iterCnt <= iter_cnt;
	 restartf.enq(?);
      endmethod
   endinterface
   interface config_read_client = config_re.dmaClient;
   interface haystack_read_client = haystack_re.dmaClient;
endmodule


