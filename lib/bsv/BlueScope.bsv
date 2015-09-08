
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
import Connectable::*;

import MemTypes::*;
import MemWriteEngine::*;
import ClientServer::*;

interface BlueScopeIndication;
   method Action triggerFired();
   method Action done();
endinterface

interface BlueScopeRequest;
   method Action start(Bit#(32) pointer, Bit#(32) len);
   method Action reset();
   method Action setTriggerMask(Bit#(64) mask);
   method Action setTriggerValue(Bit#(64) value);
endinterface

interface BlueScope#(numeric type dataWidth);
   method Action dataIn(Bit#(dataWidth) d, Bit#(dataWidth) t);
   interface BlueScopeRequest requestIfc;
   interface MemWriteClient#(dataWidth) writeClient;
endinterface

typedef enum { Idle, Enabled, Triggered } State deriving (Bits,Eq);

module mkBlueScope#(Integer samples, BlueScopeIndication indication)(BlueScope#(dataWidth))
   provisos(Add#(a__,dataWidth,64),
	    Mul#(TDiv#(dataWidth, 8), 8, dataWidth),
	    Add#(1,b__,dataWidth));
   
   let clk <- exposeCurrentClock;
   let rst <- exposeCurrentReset;
   let rv  <- mkSyncBlueScope(samples, indication, clk, rst, clk,rst);
   return rv;
endmodule

module mkSyncBlueScope#(Integer samples, BlueScopeIndication indication, Clock sClk, Reset sRst, Clock dClk, Reset dRst)(BlueScope#(dataWidth))
   provisos(Add#(a__,dataWidth,64),
	    Add#(1,b__,dataWidth),
	    Mul#(dataBytes, 8, dataWidth),
	    Div#(dataWidth,8,dataBytes));

   SyncFIFOIfc#(Bit#(dataWidth)) dfifo <- mkSyncBRAMFIFO(samples, sClk, sRst, dClk, dRst);
   Reg#(Bit#(dataWidth))       maskReg <- mkSyncReg(0, dClk, dRst, sClk);
   Reg#(Bit#(dataWidth))      valueReg <- mkSyncReg(0, dClk, dRst, sClk);
   Reg#(Bit#(1))          triggeredReg <- mkReg(0,    clocked_by sClk, reset_by sRst);   
   Reg#(State)                stateReg <- mkReg(Idle, clocked_by sClk, reset_by sRst);
   Reg#(Bit#(32))             countReg <- mkReg(0,    clocked_by sClk, reset_by sRst);
   Reg#(Bit#(MemOffsetSize)) writeOffsetReg <- mkReg(0,    clocked_by dClk, reset_by dRst);
   
   SyncPulseIfc             startPulse <- mkSyncPulse(dClk, dRst, sClk);
   SyncPulseIfc             resetPulse <- mkSyncPulse(dClk, dRst, sClk);
   SyncPulseIfc         triggeredPulse <- mkSyncPulse(sClk, sRst, dClk);
   SyncPulseIfc              donePulse <- mkSyncPulse(sClk, sRst, dClk);
   
   MemWriteEngine#(dataWidth,dataWidth,2,1) mwriter <- mkMemWriteEngine;
   
   (* descending_urgency = "resetState, startState" *)
   rule resetState if (resetPulse.pulse);
      stateReg <= Idle;
      countReg <= 0;
   endrule

   rule startState if (startPulse.pulse && !resetPulse.pulse);
      stateReg <= Enabled;
   endrule

   mkConnection(toGet(dfifo), toPut(mwriter.writeServers[0].data));

   rule writeDone;
      let tag <- mwriter.writeServers[0].done.get();
   endrule
   
   rule triggerRule if (triggeredPulse.pulse);
      indication.triggerFired;
   endrule
   rule doneRule if (donePulse.pulse);
      indication.done;
   endrule
   
   method Action dataIn(Bit#(dataWidth) data, Bit#(dataWidth) trigger);// if (stateReg != Idle);
      let e = False;
      let s = stateReg;
      let c = countReg;
      let t = False;
      let d = False;
 
      // if 'Enabled', we can transition to 'Triggered'
      if (s == Enabled && ((trigger & maskReg) == (valueReg & maskReg) && dfifo.notFull()))
      	 begin
      	    s = Triggered;
	    e = True;
	    c = c + 1;
      	    t = True;
         end
      // if 'Triggered', we can transition to 'Enabled'
      else if (s == Triggered && c == fromInteger(samples))
      	 begin
	    s = Idle;
      	    e = False;
	    c = 0;
      	    t = False;
	    d = True;
      	 end
      // if 'Triggered', we can remain in 'Triggered'
      else if (s == Triggered && c < fromInteger(samples))
      	 begin
      	    s = Triggered;
      	    e = True;
	    c = c + 1;
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
   
      if (e) begin
	 if (dfifo.notFull())
	    dfifo.enq(data);
	 else
	    $display("bluescope.stall c=%d", c);
      end
      if(t)
      	 triggeredPulse.send();
      if(d)
      	 donePulse.send();
      countReg <= c;
      stateReg <= s;
   endmethod
   
   interface BlueScopeRequest requestIfc;
      method Action start(Bit#(32) pointer, Bit#(32) len);
	 mwriter.writeServers[0].request.put(MemengineCmd {sglId: pointer, base: 0, burstLen: 8*fromInteger(valueOf(TDiv#(dataWidth,8))), len: len, tag: 0});
	 startPulse.send();
      endmethod

      method Action reset();
          resetPulse.send();
      endmethod

      method Action setTriggerMask(Bit#(64) mask);
	 maskReg <= truncate(mask);
      endmethod

      method Action setTriggerValue(Bit#(64) value);
	 valueReg <= truncate(value);
      endmethod
   endinterface
   interface writeClient = mwriter.dmaClient;
endmodule
