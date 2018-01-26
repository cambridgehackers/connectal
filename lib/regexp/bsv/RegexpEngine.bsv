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
import Probe::*;
import ConnectalMemTypes::*;
import MemReadEngine::*;
import Pipe::*;
import Dma2BRAM::*;

`include "ConnectalProjectConfig.bsv"

typedef union tagged {
   Tuple2#(Bit#(t),Int#(32)) Loc;
   Bit#(t) Done;
   Bit#(t) Ready;
   Bit#(t) Config;
   } LDR#(numeric type t) deriving (Eq,Bits);

typedef union tagged{
   Pair#(Bit#(32)) CharMap;
   Pair#(Bit#(32)) StateMap;
   Pair#(Bit#(32)) StateTransitions;
   Pair#(Bit#(32)) Search;
   Bit#(t) Retire;
  } SSV#(numeric type t) deriving (Eq,Bits);
   
interface RegexpEngine#(numeric type tw);
   interface PipeIn#(SSV#(tw)) setsearch;
   interface PipeOut#(LDR#(tw)) ldr;
endinterface

typedef Bit#(8) Char;
typedef Bit#(64) DWord;
typedef Bit#(32) Word;

module mkRegexpEngine#(Pair#(MemReadEngineServer#(64)) readers, Integer iid)(RegexpEngine#(tw))
   provisos(Log#(`MAX_NUM_STATES,5),
	    Log#(`MAX_NUM_CHARS,5),
	    Div#(64,8,nc),
	    Mul#(nc,8,64)
	    );

   let debug = False;
   let verbose = True;
   let timing = False;
   let config_re = tpl_1(readers);
   let haystack_re = tpl_2(readers);
   FIFO#(Bool) conff <- mkSizedFIFO(1);

   Reg#(Bool) readyr <- mkReg(True);
   FIFOF#(SSV#(tw)) setsearchFIFO <- mkSizedFIFOF(4);
   Probe#(Bool) ssfp <- mkProbe();
   FIFOF#(LDR#(tw)) ldrFIFO <- mkFIFOF;
   
   BRAM1Port#(Bit#(8), Bit#(8)) charMap <- mkBRAM1Server(defaultValue);
   BRAM1Port#(Bit#(5), Bit#(8)) stateMap <- mkBRAM1Server(defaultValue);
   BRAM1Port#(Bit#(10),Bit#(8)) stateTransitions <- mkBRAM1Server(defaultValue);

   BRAMWriter#(8,64) charMapWriter <- mkBRAMWriter(0, charMap.portA, config_re);
   BRAMWriter#(5,64) stateMapWriter <- mkBRAMWriter(1, stateMap.portA, config_re);
   BRAMWriter#(10,64) stateTransitionsWriter <- mkBRAMWriter(2, stateTransitions.portA, config_re);
	          
   let clk <- exposeCurrentClock;
   let rst <- exposeCurrentReset;
   Gearbox#(nc,1,Char) haystack <- mkNto1Gearbox(clk,rst,clk,rst);

   Reg#(Bit#(32)) cycleCnt <- mkReg(0);
   Reg#(Bit#(32)) lastHD <- mkReg(0);
   
   FIFO#(Bit#(5)) fsmState <- mkBypassFIFO;
   Reg#(Bit#(64))  charCnt <- mkReg(0);
   Reg#(Bit#(64))   resCnt <- mkReg(0);
   Reg#(Bool)     accepted <- mkReg(False);
   FIFO#(void)    doneFifo <- mkFIFO;
   
   rule countCycles;
      if (timing) $display("******************************************** %d", cycleCnt);
      cycleCnt <= cycleCnt+1;
      //$dumpvars();
   endrule

   rule set_ssfp;
      ssfp <= setsearchFIFO.notEmpty;
   endrule
   
   rule haystackResp;
      let rv <- toGet(haystack_re.data).get;
      haystack.enq(unpack(rv.data));
      if (rv.last)
         doneFifo.enq(?);
   endrule
   
   rule haystackFinish if (!haystack.notEmpty);
      doneFifo.deq;
      ldrFIFO.enq(tagged Done fromInteger(iid));
      conff.deq;
      fsmState.deq;
      if (verbose) $display("haystackFinish");
   endrule
   
   rule finishCharMapWriter;
      conff.deq;
      let rv <- charMapWriter.finish;
      if (verbose) $display("finishCharMapWriter");
   endrule
   
   rule finishStateMapWriter;
      conff.deq;
      let rv <- stateMapWriter.finish;
      if (verbose) $display("finishStateMapWriter");
   endrule

   rule finishStateTransitionsWriter;
      conff.deq;
      let rv <- stateTransitionsWriter.finish;
      if (verbose) $display("finishStateTransitionsWriter");
      ldrFIFO.enq(tagged Config fromInteger(iid));
   endrule
   
   rule lookup_state;
      lastHD <= cycleCnt;
      if (debug) $display("deq haystack(%d)", cycleCnt-lastHD);
      haystack.deq;
      charCnt <= charCnt+1;
      let fsm_addr <- toGet(fsmState).get;
      charMap.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:haystack.first[0], datain:?});
      stateMap.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:fsm_addr, datain:?});
   endrule
   
   rule resolve_state;
      let mapped_char <- charMap.portA.response.get;
      let mapped_state <- stateMap.portA.response.get;
      Bit#(10) ns_addr = {mapped_state[4:0],mapped_char[4:0]};
      let accept = mapped_state[7]==1;
      resCnt <= resCnt+1;
      if (accept) begin
	 if (debug) $display("accept %d", resCnt);
	 ldrFIFO.enq(tagged Loc tuple2(fromInteger(iid),unpack(truncate(resCnt))));
	 accepted <= accept;
	 fsmState.enq(0);
      end
      else begin
	 stateTransitions.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:ns_addr, datain:?});
      end
   endrule
      
   rule next_state;
      let new_state <- stateTransitions.portA.response.get;
      fsmState.enq(truncate(new_state));
   endrule
   
   // the following case statement is much cleaner, but bsc doesn't compiler it
   // correctly.  As a result, I broke it up into four rules, which seems to work (mdk)
   //
   // rule setsearch_r;
   //    let ssv <- toGet(setsearchFIFO).get;
   //    conff.enq(True);
   //    case (ssv) matches
   // 	 tagged CharMap .p:
   // 	 begin
   // 	    match {.pointer, .len}  = p;
   // 	    if (verbose) $display("setupCharMap %d %h", pointer, len);
   // 	    charMapWriter.start(pointer, 0, minBound, maxBound);
   // 	 end
   // 	 tagged StateMap .p:
   // 	 begin
   // 	    match {.pointer, .len}  = p;
   // 	    if (verbose) $display("setupStateMap %d %h", pointer, len);
   // 	    stateMapWriter.start(pointer, 0, minBound, maxBound);
   // 	 end
   // 	 tagged StateTransitions .p:
   // 	 begin
   // 	    match {.pointer, .len}  = p;
   // 	    if (verbose) $display("setupStateTransitions %d %h", pointer, len);
   // 	    stateTransitionsWriter.start(pointer, 0, minBound, maxBound);
   // 	 end
   // 	 tagged Search .p:
   // 	 begin
   // 	    match {.pointer, .len}  = p;
   // 	    if (verbose) $display("setupSearch %d %d", pointer, len);
   // 	    haystack_re.request.put(MemengineCmd{sglId:pointer, base:0, len:len, burstLen:16*fromInteger(valueOf(nc))});
   // 	    charCnt <= 0;
   // 	    resCnt <= 0;
   // 	    fsmState.enq(0);
   // 	 end
   // 	 tagged Retire .r:
   // 	 begin
   // 	    readyr <= True;
   // 	    if (verbose) $display("Retire %d", r);
   // 	 end
   //    endcase
   // endrule

   rule setsearch_r_0 if (setsearchFIFO.first matches tagged CharMap .p);
      setsearchFIFO.deq;
      conff.enq(True);
      match {.pointer, .len}  = p;
      if (verbose) $display("setupCharMap %d %h", pointer, len);
      charMapWriter.start(pointer, 0, minBound, maxBound);
   endrule
   rule setsearch_r_1 if (setsearchFIFO.first matches tagged StateMap .p);
      setsearchFIFO.deq;
      conff.enq(True);
      match {.pointer, .len}  = p;
      if (verbose) $display("setupStateMap %d %h", pointer, len);
      stateMapWriter.start(pointer, 0, minBound, maxBound);
   endrule
   rule setsearch_r_2 if (setsearchFIFO.first matches tagged StateTransitions .p);
      setsearchFIFO.deq;
      conff.enq(True);
      match {.pointer, .len}  = p;
      if (verbose) $display("setupStateTransitions %d %h", pointer, len);
      stateTransitionsWriter.start(pointer, 0, minBound, maxBound);
   endrule
   rule setsearch_r_3 if (setsearchFIFO.first matches tagged Search .p);
      setsearchFIFO.deq;
      conff.enq(True);
      match {.pointer, .len}  = p;
      if (verbose) $display("setupSearch %d %d", pointer, len);
      haystack_re.request.put(MemengineCmd{sglId:pointer, base:0, len:len, burstLen:16*fromInteger(valueOf(nc)), tag: 0});
      charCnt <= 0;
      resCnt <= 0;
      fsmState.enq(0);
   endrule
   rule setsearch_r_4 if (setsearchFIFO.first matches tagged Retire .r);
      setsearchFIFO.deq;
      readyr <= True;
      if (verbose) $display("Retire %d", r);
   endrule

   rule ready_r if (readyr);
      ldrFIFO.enq(tagged  Ready fromInteger(iid));
      readyr <= False;
   endrule

   interface PipeIn setsearch = toPipeIn(setsearchFIFO);
   interface PipeOut ldr = toPipeOut(ldrFIFO);

endmodule
