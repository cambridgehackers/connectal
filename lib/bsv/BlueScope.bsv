
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

import MemTypes::*;
import MemUtils::*;
import ClientServer::*;

interface BlueScopeIndication;
   method Action triggerFired();
endinterface

interface BlueScopeRequest;
   method Action start(Bit#(32) pointer);
   method Action reset();
   method Action setTriggerMask(Bit#(64) mask);
   method Action setTriggerValue(Bit#(64) value);
endinterface

interface BlueScope#(numeric type dataWidth);
   method Action dataIn(Bit#(dataWidth) d, Bit#(dataWidth) t);
   interface BlueScopeRequest requestIfc;
   interface ObjectWriteClient#(dataWidth) writeClient;
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
   Reg#(ObjectPointer) pointerReg <- mkSyncReg(0, dClk, dRst, sClk);
   Reg#(Bit#(dataWidth))       maskReg <- mkSyncReg(0, dClk, dRst, sClk);
   Reg#(Bit#(dataWidth))      valueReg <- mkSyncReg(0, dClk, dRst, sClk);
   Reg#(Bit#(1))          triggeredReg <- mkReg(0,    clocked_by sClk, reset_by sRst);   
   Reg#(State)                stateReg <- mkReg(Idle, clocked_by sClk, reset_by sRst);
   Reg#(Bit#(32))             countReg <- mkReg(0,    clocked_by sClk, reset_by sRst);
   Reg#(Bit#(ObjectOffsetSize)) writeOffsetReg <- mkReg(0,    clocked_by dClk, reset_by dRst);
   
   SyncPulseIfc             startPulse <- mkSyncPulse(dClk, dRst, sClk);
   SyncPulseIfc             resetPulse <- mkSyncPulse(dClk, dRst, sClk);
   SyncPulseIfc         triggeredPulse <- mkSyncPulse(sClk, sRst, dClk);
   
   MemWriter#(dataWidth) mwriter <- mkMemWriter;
   
   (* descending_urgency = "resetState, startState" *)
   rule resetState if (resetPulse.pulse);
      stateReg <= Idle;
      countReg <= 0;
   endrule

   rule startState if (startPulse.pulse && !resetPulse.pulse);
      stateReg <= Enabled;
   endrule

   rule writeReq if (dfifo.notEmpty);
      let bl = fromInteger(valueOf(dataBytes)) * 2;
      mwriter.writeServer.writeReq.put(ObjectRequest { pointer: pointerReg, offset: zeroExtend(writeOffsetReg), burstLen: bl, tag: 0});
      writeOffsetReg <= writeOffsetReg + bl;
   endrule

   rule  writeData;
      //$display("mkSyncBlueScope::writeData");
      dfifo.deq();
      mwriter.writeServer.writeData.put(ObjectData { data: dfifo.first, tag: 0});
   endrule
   
   rule writeDone;
      let tag <- mwriter.writeServer.writeDone.get();
   endrule
   
   rule triggerRule if (triggeredPulse.pulse);
      indication.triggerFired;
   endrule
   
   method Action dataIn(Bit#(dataWidth) data, Bit#(dataWidth) trigger) if (stateReg != Idle);
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
      if(t)
      	 triggeredPulse.send();
      countReg <= c;
      stateReg <= s;
   endmethod
   
   interface BlueScopeRequest requestIfc;
      method Action start(Bit#(32) pointer);
         pointerReg <= pointer;
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
   interface writeClient = mwriter.writeClient;
endmodule
