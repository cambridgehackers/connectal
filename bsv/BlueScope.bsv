
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

import Clocks::*;
import FIFO::*;
import FIFOF::*;
import BRAMFIFO::*;
import GetPut::*;

import AxiDMA::*;
import ClientServer::*;

interface BlueScope#(numeric type dataWidth, numeric type triggerWidth);
    method Action setTriggerMask(Bit#(triggerWidth) mask);
    method Action setTriggerValue(Bit#(triggerWidth) value);
    method Action start();
    method Action clear();
    method Action dataIn(Bit#(dataWidth) d, Bit#(triggerWidth) t);
    interface Get#(void) triggers;
endinterface

typedef enum { Idle, Enabled, Triggered } State deriving (Bits,Eq);

module mkBlueScope#(Integer samples, WriteChan wchan)(BlueScope#(dataWidth,triggerWidth))
   provisos (Add#(dataWidth,0,64));
   
   let clk <- exposeCurrentClock;
   let rst <- exposeCurrentReset;
   let rv  <- mkSyncBlueScope(samples, wchan, clk, rst, clk,rst);
   return rv;
endmodule

module mkSyncBlueScope#(Integer samples, WriteChan wchan, Clock sClk, Reset sRst, Clock dClk, Reset dRst)(BlueScope#(dataWidth, triggerWidth)) 
   provisos (Add#(dataWidth,0,64));

   SyncFIFOIfc#(Bit#(dataWidth)) dfifo <- mkSyncBRAMFIFO(samples, sClk, sRst, dClk, dRst);

   Reg#(Bit#(triggerWidth))    maskReg <- mkReg(0,    clocked_by sClk, reset_by sRst);
   Reg#(Bit#(triggerWidth))   valueReg <- mkReg(0,    clocked_by sClk, reset_by sRst);
   Reg#(Bit#(1))          triggeredReg <- mkReg(0,    clocked_by sClk, reset_by sRst);   
   Reg#(State)                stateReg <- mkReg(Idle, clocked_by sClk, reset_by sRst);
   Reg#(Bit#(32))             countReg <- mkReg(0,    clocked_by sClk, reset_by sRst);
   FIFOF#(void)                  tfifo <- mkFIFOF(    clocked_by sClk, reset_by sRst);
   
   rule writeReq if (stateReg == Enabled);
      wchan.writeReq.put(?);
   endrule
   
   rule  writeData;
      dfifo.deq;
      wchan.writeData.put(dfifo.first);
   endrule
   
   rule writeDone;
      wchan.writeDone.get;
   endrule

   method Action setTriggerMask(Bit#(triggerWidth) mask);
      maskReg <= mask;
   endmethod

   method Action setTriggerValue(Bit#(triggerWidth) value);
      valueReg <= value;
   endmethod

   method Action start();
      stateReg <= Enabled;
   endmethod

   method Action clear();
      stateReg <= Idle;
      countReg <= 0;
   endmethod
   
   method Action dataIn(Bit#(dataWidth) data, Bit#(triggerWidth) trigger) if (stateReg != Idle);
   
      let e = False;
      let s = stateReg;
      let c = countReg;
      let t = False;
 
      // if 'Enabled', we can transition to 'Triggered'
      if (s == Enabled && ((trigger & maskReg) == (valueReg & maskReg)))
	 begin
	    s = Triggered;
	    e = True;
	    c = c+1;
	    t = True;
         end
      // if 'Triggered', we can transition to 'Enabled'
      else if (s == Triggered && c == fromInteger(samples))
	 begin
	    s = Enabled;
	    e = False;
	    c = 0;
	    t = False;
	 end
      // if 'Triggered', we can remain in 'Triggered'
      else if (s == Triggered && c <= fromInteger(samples))
	 begin
	    s = Triggered;
	    e = True;
	    c = c+1;
	    t = False;
	 end
      // else we must be enabled waiting for a Trigger
      else 
	 begin
	    s = s;
	    e = e;
	    c = c;
	    t = t;
	 end
   
      if(e && dfifo.notFull)
	 dfifo.enq(data);
      if(t && tfifo.notFull)
	 tfifo.enq(?);
      countReg <= c;
      stateReg <= s;
      
   endmethod

   interface Get triggers = toGet(tfifo);
endmodule
