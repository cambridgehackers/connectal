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
import StmtFSM::*;
import ClientServer::*;
import GetPut::*;
import Connectable::*;
import ConnectalMemTypes::*;
import MemReadEngine::*;
import Pipe::*;
import Dma2BRAM::*;
import RegexpEngine::*;

`include "ConnectalProjectConfig.bsv"

interface RegexpRequest;
   method Action setup(Bit#(32) mapSGLId, Bit#(32) mapLen);
   method Action search(Bit#(32) token, Bit#(32) haystackSGLId, Bit#(32) haystackLen);
   method Action retire(Bit#(32) token);
endinterface

interface RegexpIndication;
   method Action setupComplete(Bit#(32) token);
   method Action searchResult(Bit#(32) token, Int#(32) v);
endinterface

interface Regexp#(numeric type busWidth);
   interface RegexpRequest request;
   interface Vector#(1, MemReadClient#(busWidth)) config_read_client;
   interface Vector#(1, MemReadClient#(busWidth)) haystack_read_client;
endinterface

typedef `DEGPAR DegPar;

typedef enum {Config_charMap, Config_stateMap, Config_stateTransitions} RegexpState deriving (Eq,Bits);

module mkRegexp#(RegexpIndication indication)(Regexp#(64))
   provisos( Log#(`MAX_NUM_STATES,5)
	    ,Log#(`MAX_NUM_CHARS,5)
	    ,Div#(64,8,nc)
	    ,Mul#(nc,8,64)
	    ,Add#(0,DegPar,p)
	    ,Log#(p,lp)
	    );

   MemReadEngine#(64,64,1,p) config_re <- mkMemReadEngine;
   MemReadEngine#(64,64,2,p) haystack_re <- mkMemReadEngine;
   let read_servers = zip(config_re.readServers,haystack_re.readServers);
   Vector#(p, RegexpEngine#(lp)) rees <- mapM(uncurry(mkRegexpEngine), zip(read_servers,genVector));
   Reg#(RegexpState) state <- mkReg(Config_charMap);

   let readyFIFO <- mkSizedFIFOF(valueOf(p));
   Vector#(p, PipeOut#(LDR#(lp))) ldrPipes;   
   
   FIFOF#(Tuple2#(Bit#(lp), SSV#(lp))) setsearchFIFO <- mkFIFOF;
   UnFunnelPipe#(1,p,SSV#(lp),1) setsearchPipeUnFunnel <- mkUnFunnelPipesPipelined(cons(toPipeOut(setsearchFIFO),nil));

   for(Integer i = 0; i < valueOf(p); i=i+1) begin
      ldrPipes[i] = rees[i].ldr;
      mkConnection(setsearchPipeUnFunnel[i],rees[i].setsearch);
   end
   FunnelPipe#(1,p,LDR#(lp),1) ldr <- mkFunnelPipesPipelined(ldrPipes);
   
   rule ldrr;
      let rv <- toGet(ldr[0]).get;
      case (rv) matches
   	 tagged Ready  .r : readyFIFO.enq(r);
   	 tagged Done   .d : indication.searchResult(extend(d), -1);
   	 tagged Loc    .l : indication.searchResult(extend(tpl_1(l)), tpl_2(l));
   	 tagged Config .c : indication.setupComplete(extend(c));
      endcase
   endrule

   let setupFIFO <- mkSizedFIFO(4);
   rule setup_r;
      match {.sglId, .len} <- toGet(setupFIFO).get;
      $display("mkRegexp::setup(%d) %d %d %d", readyFIFO.first,sglId, len, state);
      case (state) matches
	 Config_charMap:  
	 begin
	    state <= Config_stateMap;
	    setsearchFIFO.enq(tuple2(readyFIFO.first,tagged CharMap tuple2(sglId,len)));
	 end
	 Config_stateMap: 
	 begin
	    state <= Config_stateTransitions;
	    setsearchFIFO.enq(tuple2(readyFIFO.first,tagged StateMap tuple2(sglId,len)));
	 end
	 Config_stateTransitions:  
	 begin
	    readyFIFO.deq;
	    state <= Config_charMap;
	    setsearchFIFO.enq(tuple2(readyFIFO.first,tagged StateTransitions tuple2(sglId,len)));
	 end
      endcase      
   endrule

   interface config_read_client = cons(config_re.dmaClient, nil);
   interface haystack_read_client = cons(haystack_re.dmaClient, nil);
      
   interface RegexpRequest request;
      method Action setup(Bit#(32) sglId, Bit#(32) len);	 
	 setupFIFO.enq(tuple2(sglId,len));
      endmethod
      method Action search(Bit#(32) token, Bit#(32) sglId, Bit#(32) len);
	 $display("mkRegexp::search %d %d %d", token, sglId, len);
	 setsearchFIFO.enq(tuple2(truncate(token),tagged Search tuple2(sglId,len)));
      endmethod
      method Action retire(Bit#(32) token);
	 Bit#(lp) tok = truncate(token);
	 $display("mkRegexp::retire(%d)", tok);
	 setsearchFIFO.enq(tuple2(tok,tagged Retire tok));
      endmethod
   endinterface

endmodule
