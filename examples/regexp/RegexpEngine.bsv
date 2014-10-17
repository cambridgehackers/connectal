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

import AxiMasterSlave::*;
import MemTypes::*;
import MemreadEngine::*;
import Pipe::*;
import Dma2BRAM::*;

typedef union tagged {
   Tuple2#(Bit#(t),Int#(32)) Loc;
   Bit#(t) Done;
   Bit#(t) Ready;
   } LDR#(numeric type t) deriving (Eq,Bits);

interface RegexpEngine#(numeric type tw);
   interface PipeIn#(Pair#(Bit#(32))) setsearch;
   interface PipeOut#(LDR#(tw)) ldr;
endinterface

typedef Bit#(8) Char;
typedef Bit#(64) DWord;
typedef Bit#(32) Word;

typedef enum {Config_charMap, Config_stateMap, Config_stateTransitions, Search} RegexpState deriving (Eq,Bits);

module mkRegexpEngine#(Pair#(MemreadServer#(64)) readers, Integer iid)(RegexpEngine#(tw))
   provisos(Log#(`MAX_NUM_STATES,5),
	    Log#(`MAX_NUM_CHARS,5),
	    Div#(64,8,nc),
	    Mul#(nc,8,64)
	    );

   let debug = False;
   let config_re = tpl_1(readers);
   let haystack_re = tpl_2(readers);
   FIFO#(Bool) conff <- mkSizedFIFO(1);
   Reg#(RegexpState) state <- mkReg(Config_charMap);

   Reg#(Bool) readyr <- mkReg(True);
   FIFOF#(Pair#(Bit#(32))) setsearchFIFO <- mkSizedFIFOF(3);
   FIFOF#(LDR#(tw)) ldrFIFO <- mkFIFOF;
   
   BRAM1Port#(Bit#(8), Bit#(8)) charMap <- mkBRAM1Server(defaultValue);
   BRAM1Port#(Bit#(5), Bit#(8)) stateMap <- mkBRAM1Server(defaultValue);
   BRAM1Port#(Bit#(10),Bit#(8)) stateTransitions <- mkBRAM1Server(defaultValue);

   BRAMWriter#(8,64) charMapWriter <- mkBRAMWriter(0, charMap.portA, config_re.cmdServer, config_re.dataPipe);
   BRAMWriter#(5,64) stateMapWriter <- mkBRAMWriter(1, stateMap.portA, config_re.cmdServer, config_re.dataPipe);
   BRAMWriter#(10,64) stateTransitionsWriter <- mkBRAMWriter(2, stateTransitions.portA, config_re.cmdServer, config_re.dataPipe);
	          
   let clk <- exposeCurrentClock;
   let rst <- exposeCurrentReset;
   Gearbox#(nc,1,Char) haystack <- mkNto1Gearbox(clk,rst,clk,rst);

   rule haystackResp;
      let rv <- toGet(haystack_re.dataPipe).get;
      haystack.enq(unpack(rv));
   endrule
   
   rule haystackFinish if (!haystack.notEmpty);
      let rv <- haystack_re.cmdServer.response.get;
      ldrFIFO.enq(tagged Done fromInteger(iid));
      readyr <= True;
      conff.deq;
      $display("Done");
   endrule
   
   rule finishCharMapWriter;
      conff.deq;
      let rv <- charMapWriter.finish;
      if (debug) $display("finishCharMapWriter");
   endrule
   
   rule finishStateMapWriter;
      conff.deq;
      let rv <- stateMapWriter.finish;
      if (debug) $display("finishStateMapWriter");
   endrule

   rule finishStateTransitionsWriter;
      conff.deq;
      let rv <- stateTransitionsWriter.finish;
      if (debug) $display("finishStateTransitionsWriter");
   endrule
   
   Reg#(Bool) fsmStateValid <- mkReg(True);
   Reg#(Bit#(5))   fsmState <- mkReg(0);
   Reg#(Bit#(64))   charCnt <- mkReg(0);
   Reg#(Bit#(64))    resCnt <- mkReg(0);
   Reg#(Bool)     accepted <- mkReg(False);

   rule lookup_state if (fsmStateValid);
      haystack.deq;
      charCnt <= charCnt+1;
      charMap.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:haystack.first[0], datain:?});
      stateMap.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:fsmState, datain:?});
      fsmStateValid <= False;
   endrule
   
   rule resolve_state;
      let mapped_char <- charMap.portA.response.get;
      let mapped_state <- stateMap.portA.response.get;
      Bit#(10) ns_addr = {mapped_state[4:0],mapped_char[4:0]};
      let accept = mapped_state[7]==1;
      resCnt <= resCnt+1;
      if (debug) $display("fsmState=%d %d", fsmState, accept);
      if (accept) begin
	 $display("accept %d", resCnt);
	 ldrFIFO.enq(tagged Loc tuple2(fromInteger(iid),unpack(truncate(resCnt))));
	 accepted <= accept;
	 fsmState <= 0;
	 fsmStateValid <= True;
      end
      else begin
	 stateTransitions.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:ns_addr, datain:?});
      end
   endrule
      
   rule next_state;
      let new_state <- stateTransitions.portA.response.get;
      fsmState <= truncate(new_state);
      fsmStateValid <= True;
   endrule
   
   rule setsearch_r;
      match {.pointer,.len} <- toGet(setsearchFIFO).get;
      conff.enq(True);
      case (state) matches
	 Config_charMap:
	 begin
	    if (debug) $display("setupCharMap %d %h", pointer, len);
	    charMapWriter.start(pointer, 0, minBound, maxBound);
	    state <= Config_stateMap;
	 end
	 Config_stateMap:
	 begin
	    if (debug) $display("setupStateMap %d %h", pointer, len);
	    stateMapWriter.start(pointer, 0, minBound, maxBound);
	    state <= Config_stateTransitions;
	 end
	 Config_stateTransitions:
	 begin
	    if (debug) $display("setupStateTransitions %d %h", pointer, len);
	    stateTransitionsWriter.start(pointer, 0, minBound, maxBound);
	    state <= Search;
	 end
	 Search:
	 begin
	    if (debug) $display("setupSearch %d %d", pointer, len);
	    haystack_re.cmdServer.request.put(MemengineCmd{sglId:pointer, base:0, len:len, burstLen:16*fromInteger(valueOf(nc))});
	    charCnt <= 0;
	    resCnt <= 0;
	    state <= Config_charMap;
	 end
      endcase
   endrule

   rule ready_r if (readyr);
      ldrFIFO.enq(tagged  Ready fromInteger(iid));
      readyr <= False;
   endrule

   interface PipeIn setsearch = toPipeIn(setsearchFIFO);
   interface PipeOut ldr = toPipeOut(ldrFIFO);

endmodule

