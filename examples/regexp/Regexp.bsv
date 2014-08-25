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
import MPEngine::*;
import MemreadEngine::*;
import Pipe::*;
import Dma2BRAM::*;

interface RegexpRequest;
   method Action setup(Bit#(32) mapPointer, Bit#(32) map_len);
   method Action search(Bit#(32) haystackPointer, Bit#(32) haystack_len, Bit#(32) iter_cnt);
endinterface

interface RegexpIndication;
   method Action searchResult(Int#(32) v);
   method Action setupComplete();
endinterface

interface Regexp#(numeric type busWidth);
   interface RegexpRequest request;
   interface ObjectReadClient#(busWidth) config_read_client;
   interface ObjectReadClient#(busWidth) haystack_read_client;
endinterface

typedef enum {Config_charMap, Config_stateMap, Config_stateTransitions, Config_finished} RegexpState deriving (Eq,Bits);

module mkRegexp#(RegexpIndication indication)(Regexp#(64))
   provisos(Log#(`MAX_NUM_STATES,5),
	    Log#(`MAX_NUM_CHARS,5),
      
	    Div#(64,8,nc),
	    Mul#(nc,8,64)

	    );

   let debug = True;
   let verbose = True;
   MemreadEngineV#(64, 1, 3) config_re <- mkMemreadEngine;
   MemreadEngineV#(64, 1, 1) haystack_re <- mkMemreadEngine;
   Reg#(RegexpState) state <- mkReg(Config_charMap);

   BRAM1Port#(Bit#(8), Bit#(8)) charMap <- mkBRAM1Server(defaultValue);
   BRAM1Port#(Bit#(5), Bit#(8)) stateMap <- mkBRAM1Server(defaultValue);
   BRAM1Port#(Bit#(10),Bit#(8)) stateTransitions <- mkBRAM1Server(defaultValue);

   BRAMWriter#(8,64) charMapWriter <- mkBRAMWriter(0, charMap.portA, config_re.readServers[0], config_re.dataPipes[0]);
   BRAMWriter#(5,64) stateMapWriter <- mkBRAMWriter(1, stateMap.portA, config_re.readServers[1], config_re.dataPipes[1]);
   BRAMWriter#(10,64) stateTransitionsWriter <- mkBRAMWriter(2, stateTransitions.portA, config_re.readServers[2], config_re.dataPipes[2]);
	          
   let clk <- exposeCurrentClock;
   let rst <- exposeCurrentReset;
   Gearbox#(nc,1,Char) haystack <- mkNto1Gearbox(clk,rst,clk,rst);

   rule haystackResp;
      let rv <- toGet(haystack_re.dataPipes[0]).get;
      haystack.enq(unpack(rv));
   endrule
   
   rule haystackFinish if (!haystack.notEmpty);
      let rv <- haystack_re.readServers[0].response.get;
      indication.searchResult(-1);
   endrule
   
   rule finishCharMapWriter;
      indication.setupComplete;
      let rv <- charMapWriter.finish;
   endrule
   
   rule finishStateMapWriter;
      indication.setupComplete;
      let rv <- stateMapWriter.finish;
   endrule

   rule finishStateTransitionsWriter;
      indication.setupComplete;
      let rv <- stateTransitionsWriter.finish;
   endrule
   
   Reg#(Bool) fsmStateValid <- mkReg(True);
   Reg#(Bit#(5))   fsmState <- mkReg(0);
   Reg#(Bit#(64))   charCnt <- mkReg(0);
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
      if (debug) $display("fsmState=%d %d", fsmState, accept);
      if (accept) begin
	 indication.searchResult(1);
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
   
   interface RegexpRequest request;
      method Action setup(Bit#(32) pointer, Bit#(32) len);
	 case (state) matches 
	    Config_charMap: 
	    begin
	       charMapWriter.start(pointer, 0, minBound, maxBound);
	       state <= Config_stateMap;
	    end
	    Config_stateMap: 
	    begin 
	       stateMapWriter.start(pointer, 0, minBound, maxBound);
	       state <= Config_stateTransitions;
	    end
	    Config_stateTransitions: 
	    begin
	       stateTransitionsWriter.start(pointer, 0, minBound, maxBound);
	       state <= Config_finished;
	    end
	 endcase	    
      endmethod
      method Action search(Bit#(32) haystack_pointer, Bit#(32) haystack_len, Bit#(32) iter_cnt) if (state == Config_finished);
	 if (debug) $display("mkRegexp.RegexpRequest.search %d %d %d", haystack_pointer, haystack_len, iter_cnt);
	 haystack_re.readServers[0].request.put(MemengineCmd{pointer:haystack_pointer, base:0, len:haystack_len, burstLen:16*fromInteger(valueOf(nc))});
      endmethod
   endinterface
   interface config_read_client = config_re.dmaClient;
   interface haystack_read_client = haystack_re.dmaClient;
endmodule





