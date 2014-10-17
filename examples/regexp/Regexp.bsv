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

import AxiMasterSlave::*;
import MemTypes::*;
import MemreadEngine::*;
import Pipe::*;
import Dma2BRAM::*;
import RegexpEngine::*;

interface RegexpRequest;
   method Action setup(Bit#(32) mapSGLId, Bit#(32) mapLen);
   method Action search(Bit#(32) token, Bit#(32) haystackSGLId, Bit#(32) haystackLen);
endinterface

interface RegexpIndication;
   method Action setupComplete(Bit#(32) token);
   method Action searchResult(Bit#(32) token, Int#(32) v);
endinterface

interface Regexp#(numeric type busWidth);
   interface RegexpRequest request;
   interface ObjectReadClient#(busWidth) config_read_client;
   interface ObjectReadClient#(busWidth) haystack_read_client;
endinterface

typedef 4 DegPar;

module mkRegexp#(RegexpIndication indication)(Regexp#(64))
   provisos(Log#(`MAX_NUM_STATES,5),
	    Log#(`MAX_NUM_CHARS,5),
	    Div#(64,8,nc),
	    Mul#(nc,8,64),
	    Log#(DegPar, ldp)
	    );

   MemreadEngineV#(64, 1, DegPar) config_re <- mkMemreadEngine;
   MemreadEngineV#(64, 1, DegPar) haystack_re <- mkMemreadEngine;
   let read_servers = zip(config_re.read_servers,haystack_re.read_servers);
   Vector#(DegPar, RegexpEngine#(ldp)) rees <- mapM(uncurry(mkRegexpEngine), zip(read_servers,genVector));
   Reg#(RegexpState) state <- mkReg(Config_charMap);

   let readyFIFO <- mkSizedFIFOF(valueOf(DegPar));
   Vector#(DegPar, PipeOut#(LDR#(ldp))) ldrPipes;   
   
   FIFOF#(Tuple2#(Bit#(ldp), Pair#(Bit#(32)))) setsearchFIFO <- mkFIFOF;
   UnFunnelPipe#(1,DegPar,Pair#(Bit#(32)),1) setsearchPipeUnFunnel <- mkUnFunnelPipesPipelined(cons(toPipeOut(setsearchFIFO),nil));

   for(Integer i = 0; i < valueOf(DegPar); i=i+1) begin
      ldrPipes[i] = rees[i].ldr;
      mkConnection(setsearchPipeUnFunnel[i],rees[i].setsearch);
   end
   FunnelPipe#(1,DegPar,LDR#(ldp),1) ldr <- mkFunnelPipesPipelined(ldrPipes);
   
   rule ldrr;
      let rv <- toGet(ldr[0]).get;
      case (rv) matches
	 tagged Ready .r : begin
	    $display("Ready %d", r);
	    readyFIFO.enq(r);
	 end
	 tagged Done  .d : begin
	    $display("Done %d", d);
	    indication.searchResult(extend(d), -1);
	 end
	 tagged Loc   .l : begin
	    $display("Loc %d", tpl_2(l));
	    indication.searchResult(extend(tpl_1(l)), tpl_2(l));
	 end
      endcase
   endrule
      
   interface config_read_client = config_re.dmaClient;
   interface haystack_read_client = haystack_re.dmaClient;

   interface RegexpRequest request;
      method Action setup(Bit#(32) sglId, Bit#(32) len) if (state != Search);
	 setsearchFIFO.enq(tuple2(readyFIFO.first,tuple2(sglId,len)));
	 case (state) matches
	    Config_charMap:
            begin
	       state <= Config_stateMap;
	    end
	    Config_stateMap:
	    begin
               state <= Config_stateTransitions;
	    end
	    Config_stateTransitions: 
	    begin
	       state <= Config_charMap;
	       indication.setupComplete(extend(readyFIFO.first));
	       readyFIFO.deq;
	    end
	 endcase
      endmethod
      method Action search(Bit#(32) token, Bit#(32) sglId, Bit#(32) len);
	 $display("search %d %d %d", token, sglId, len);
	 setsearchFIFO.enq(tuple2(truncate(token),tuple2(sglId,len)));
      endmethod
   endinterface

endmodule

