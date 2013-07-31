
// Copyright (c) 2013 Nokia, Inc.
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

import Zynq::*;

interface PeriodicIndications;
    method Action fired(Bit#(8) leds);
    method Action timerUpdated(Bit#(32) v);
endinterface

interface Periodic;
    method Action setPeriod(Bit#(32) v);
    method Action start();
    method Action stop();
    interface LEDS leds;
endinterface

module mkPeriodic#(PeriodicIndications indications)(Periodic);
    Reg#(Bit#(8)) ledsReg <- mkReg(0);
    Reg#(Bit#(32)) counter <- mkReg(0);
    Reg#(Bit#(32)) limit <- mkReg(0);
    Reg#(Bool) running <- mkReg(False);

    rule count if (running);
        let count = counter + 1;
	if (count >= limit)
	begin
	    count = 0;
	    indications.fired(ledsReg);
	    ledsReg <= ledsReg + 1;
	end
	counter <= count;
    endrule

    method Action start();
        running <= True;
    endmethod

    method Action stop();
        running <= False;
    endmethod

    method Action setPeriod(Bit#(32) v);
        limit <= v;
	indications.timerUpdated(v);
    endmethod

    interface LEDS leds;
        method Bit#(8) leds();
            return ledsReg;
	endmethod
    endinterface
endmodule
