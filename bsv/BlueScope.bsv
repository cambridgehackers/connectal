
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

import FIFOF::*;
import BRAMFIFO::*;

interface BlueScope#(type dataWidth, type triggerWidth);
    method Action setTriggerMask(Bit#(triggerWidth) mask);
    method Action setTriggerValue(Bit#(triggerWidth) value);
    method Action start();
    method Action clear();
    method Action dataIn(Bit#(dataWidth) d, Bit#(triggerWidth) t);
    method ActionValue#(Bit#(dataWidth)) dataOut;
    method Bit#(32) sampleCount();
endinterface

typedef enum { Idle, Enabled, Running } State deriving (Bits,Eq);

module mkBlueScope#(Integer samples)(BlueScope#(dataWidth, triggerWidth)) provisos (Add#(1,a,dataWidth));
    FIFOF#(Bit#(dataWidth)) dfifo <- mkSizedBRAMFIFOF(samples);
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
