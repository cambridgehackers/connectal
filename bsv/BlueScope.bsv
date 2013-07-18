
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
import Gray              ::*;
import GrayCounter       ::*;

interface BlueScope#(type dataWidth, type triggerWidth);
    method Action setTriggerMask(Bit#(triggerWidth) mask);
    method Action setTriggerValue(Bit#(triggerWidth) value);
    method Action start();
    method Action clear();
    method Action dataIn(Bit#(dataWidth) d, Bit#(triggerWidth) t);
    method ActionValue#(Bit#(dataWidth)) dataOut;
    method Bit#(32) sampleCount();
    method Bool triggered();
endinterface

typedef enum { Idle, Enabled, Running } State deriving (Bits,Eq);

module mkBlueScope#(Integer samples)(BlueScope#(dataWidth, triggerWidth)) provisos (Add#(1,a,dataWidth));
    FIFO#(Bit#(dataWidth)) dfifo <- mkSizedBRAMFIFO(samples);
    Reg#(Bit#(triggerWidth)) maskReg <- mkReg(0);
    Reg#(Bit#(triggerWidth)) valueReg <- mkReg(0);

    Reg#(State) stateReg <- mkReg(Idle);
    Reg#(Bit#(32)) sampleCountReg <- mkReg(0);

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
        dfifo.clear();
	stateReg <= Idle;
	sampleCountReg <= 0;
    endmethod
    method Action dataIn(Bit#(dataWidth) d, Bit#(triggerWidth) t) if (stateReg != Idle);
        State s = stateReg;
        if (s == Enabled && ((t & maskReg) == (valueReg & maskReg)))
	begin
	    s = Running;
	    stateReg <= s;
        end
	if (s == Running)
	begin
	    dfifo.enq(d);
	    sampleCountReg <= sampleCountReg + 1;
	end
    endmethod
    method ActionValue#(Bit#(dataWidth)) dataOut;
        dfifo.deq;
        return dfifo.first;
    endmethod
    method Bit#(32) sampleCount();
        return sampleCountReg;
    endmethod
endmodule

module mkSyncBlueScope#(Integer samples, Clock sClk, Reset sRst, Clock dClk, Reset dRst)(BlueScope#(dataWidth, triggerWidth)) provisos (Add#(1,a,dataWidth));
    SyncFIFOIfc#(Bit#(dataWidth)) dfifo <- mkSyncBRAMFIFO(samples, sClk, sRst, dClk, dRst);
    Reg#(Bit#(triggerWidth)) maskReg <- mkSyncReg(0, dClk, dRst, sClk);
    Reg#(Bit#(triggerWidth)) valueReg <- mkSyncReg(0, dClk, dRst, sClk);
    Reg#(Bit#(1)) triggeredReg <- mkReg(0, clocked_by dClk, reset_by dRst);

    SyncPulseIfc enablePulse <- mkSyncPulse(dClk, dRst, sClk);
    SyncPulseIfc resetPulse <- mkSyncPulse(dClk, dRst, sClk);
    SyncPulseIfc triggeredPulse <- mkSyncPulse(sClk, sRst, dClk);
    Reg#(State) stateReg <- mkReg(Idle, clocked_by sClk, reset_by sRst);
    GrayCounter#(32) sampleCountReg <- mkGrayCounter(unpack(0), dClk, dRst, clocked_by sClk, reset_by sRst);

    rule reset if (resetPulse.pulse == True);
        stateReg <= Idle;
	sampleCountReg.sWriteBin(unpack(0));
    endrule
    rule enable if (enablePulse.pulse == True);
        stateReg <= Enabled;
    endrule
    rule triggeredRule if (triggeredPulse.pulse == True);
        triggeredReg <= 1;
    endrule

    method Action setTriggerMask(Bit#(triggerWidth) mask);
        maskReg <= mask;
    endmethod
    method Action setTriggerValue(Bit#(triggerWidth) value);
        valueReg <= value;
    endmethod
    method Action start();
	enablePulse.send;
    endmethod
    method Action clear();
        // not in SyncFIFOIfc dfifo.clear();
	resetPulse.send;
	triggeredReg <= 0;
    endmethod
    method Action dataIn(Bit#(dataWidth) d, Bit#(triggerWidth) t) if (stateReg != Idle);
        State s = stateReg;
	if (!dfifo.notFull)
	begin
	    s = Idle;
	end

        if (s == Enabled && ((t & maskReg) == (valueReg & maskReg)))
	begin
	    s = Running;
	    triggeredPulse.send;
        end
	if (s == Running)
	begin
	    dfifo.enq(d);
	    sampleCountReg.incr;
	end
	stateReg <= s;
    endmethod
    method ActionValue#(Bit#(dataWidth)) dataOut;
        dfifo.deq;
        return dfifo.first;
    endmethod
    method Bit#(32) sampleCount();
        return sampleCountReg.dReadBin();
    endmethod
    method Bool triggered();
        return triggeredReg() == 1 ? True : False;
    endmethod
endmodule
