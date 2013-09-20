
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

interface BlueScopeIndication;
   method Action triggerFired();
   method Action reportStateDbg(Bit#(64) mask, Bit#(64) value);
endinterface

interface BlueScopeRequest;
   method Action start();
   method Action reset();
   method Action setTriggerMask(Bit#(64) mask);
   method Action setTriggerValue(Bit#(64) value);
   method Action getStateDbg();
endinterface

interface BlueScopeInternal;
   method Action dataIn(Bit#(64) d, Bit#(64) t);
   interface BlueScopeRequest requestIfc;
endinterface

typedef enum { Idle, Enabled, Triggered } State deriving (Bits,Eq);

module mkBlueScopeInternal#(Integer samples, WriteChan wchan, BlueScopeIndication indication)(BlueScopeInternal);
   let clk <- exposeCurrentClock;
   let rst <- exposeCurrentReset;
   let rv  <- mkSyncBlueScopeInternal(samples, wchan, indication, clk, rst, clk,rst);
   return rv;
endmodule

module mkSyncBlueScopeInternal#(Integer samples, WriteChan wchan, BlueScopeIndication indication, Clock sClk, Reset sRst, Clock dClk, Reset dRst)(BlueScopeInternal);
   SyncFIFOIfc#(Bit#(64)) dfifo <- mkSyncBRAMFIFO(samples, sClk, sRst, dClk, dRst);
   Reg#(Bit#(64))    maskReg <- mkReg(0,    clocked_by sClk, reset_by sRst);
   Reg#(Bit#(64))   valueReg <- mkReg(0,    clocked_by sClk, reset_by sRst);
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
   
   rule trigger;
      indication.triggerFired;
      tfifo.deq;
   endrule
   
   method Action dataIn(Bit#(64) data, Bit#(64) trigger) if (stateReg != Idle);
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
   
   interface BlueScopeRequest requestIfc;
      method Action start();
	 stateReg <= Enabled;
      endmethod

      method Action reset();
	 stateReg <= Idle;
	 countReg <= 0;
      endmethod

      method Action setTriggerMask(Bit#(64) mask);
	 maskReg <= mask;
      endmethod

      method Action setTriggerValue(Bit#(64) value);
	 valueReg <= value;
      endmethod

      method Action getStateDbg();
	 indication.reportStateDbg(maskReg,valueReg);
      endmethod

   endinterface

endmodule
