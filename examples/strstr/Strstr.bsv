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
import GetPutF::*;
import Vector::*;
import BRAM::*;
import Gearbox::*;

import AxiMasterSlave::*;
import Dma::*;
import DmaUtils::*;
import MPEngine::*;

interface StrstrRequest;
   method Action setup(Bit#(32) needlePointer, Bit#(32) mpNextPointer, Bit#(32) needle_len);
   method Action search(Bit#(32) haystackPointer, Bit#(32) haystack_len, Bit#(32) iter_cnt);
endinterface

interface StrstrIndication;
   method Action searchResult(Int#(32) v);
   method Action setupComplete();
endinterface

module mkStrstrRequest#(StrstrIndication indication,
			Vector#(p,DmaReadServer#(busWidth))   haystack_read_servers,
			Vector#(p,DmaReadServer#(busWidth))     needle_read_servers,
			Vector#(p,DmaReadServer#(busWidth))    mp_next_read_servers )(StrstrRequest)
   
   provisos(Add#(a__, 8, busWidth),
	    Div#(busWidth,8,nc),
	    Mul#(nc,8,busWidth),
	    Add#(1, b__, nc),
	    Add#(c__, 32, busWidth),
	    Add#(1, d__, TDiv#(busWidth, 32)),
	    Mul#(TDiv#(busWidth, 32), 32, busWidth),
	    Log#(p,lp));
   
   Reg#(Bit#(32)) needleLen <- mkReg(0);
   
   Vector#(p, FIFOF#(void)) confs <- replicateM(mkFIFOF);
   Vector#(p, FIFOF#(void)) comps <- replicateM(mkFIFOF);
   Vector#(p, FIFOF#(Int#(32))) locs <- replicateM(mkFIFOF);
   Reg#(Bit#(32)) iterCnt <- mkReg(0);
   Reg#(Bit#(32)) haystackPointer <- mkReg(0);
   Reg#(Bit#(32)) haystackLen <- mkReg(0);
   FIFO#(void) restartf <- mkSizedFIFO(1);
   
	       
   Vector#(p, MPEngine) engines;
   for(Integer i = 0; i < valueOf(p); i=i+1) begin
      let iv = fromInteger(i);
      engines[iv] <- mkMPEngine(comps[iv], confs[iv], locs[iv], haystack_read_servers[iv], needle_read_servers[iv], mp_next_read_servers[iv]);
   end
   
   rule confr;
      for(Integer i = 0; i < valueOf(p); i=i+1) 
	 confs[fromInteger(i)].deq;
      indication.setupComplete;
   endrule
   
   for(Integer i = 0; i < valueOf(p); i=i+1)
      rule resr;
	 let rv = locs[fromInteger(i)].first;
	 locs[fromInteger(i)].deq;
	 indication.searchResult(rv);
      endrule
   
   rule restartr(iterCnt > 0);
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
      Bool locs_empty = True;
      for(Integer i = 0; i < valueOf(p); i=i+1)
	 locs_empty = locs_empty && !locs[fromInteger(i)].notEmpty;
      for(Integer i = 0; i < valueOf(p); i=i+1)
	 comps[fromInteger(i)].deq;
      if(iterCnt==0)
	 _when_(locs_empty) (indication.searchResult(-1));
      else
	 restartf.enq(?);
   endrule
      
   method Action setup(Bit#(32) needle_pointer, Bit#(32) mpNext_pointer, Bit#(32) needle_len);
      $display("setup(%d %d %d)", needle_pointer, mpNext_pointer, needle_len);
      needleLen <= needle_len;
      for(Integer i = 0; i < valueOf(p); i=i+1)
	 engines[fromInteger(i)].setup(needle_pointer, mpNext_pointer, needle_len);
   endmethod

   method Action search(Bit#(32) haystack_pointer, Bit#(32) haystack_len, Bit#(32) iter_cnt);
      haystackLen <= haystack_len;
      haystackPointer <= haystack_pointer;
      iterCnt <= iter_cnt;
      restartf.enq(?);
   endmethod
endmodule
