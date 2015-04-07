// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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
import StmtFSM::*;


interface FrequencyCounter;
   method Action start(Bit#(32) periodA);
   method ActionValue#(Bit#(32)) elapsedCycles();
endinterface

module mkFrequencyCounter#(Clock clock, Reset reset)(FrequencyCounter);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();

   Reg#(Bit#(32)) counter <- mkReg(0, clocked_by clock, reset_by reset);
   SyncPulseIfc startElapsed <- mkSyncHandshake(defaultClock, defaultReset, clock);
   SyncPulseIfc getElapsed <- mkSyncHandshake(defaultClock, defaultReset, clock);
   SyncFIFOIfc#(Bit#(32)) elapsedFifo <- mkSyncFIFO(2, clock, reset, defaultClock);

   rule cyclecount;
      let c = counter + 1;
      if (startElapsed.pulse())
	 c = 0;
      counter <= c;
   endrule
   rule calcElapsed if (getElapsed.pulse());
      elapsedFifo.enq(counter);
   endrule

   Reg#(Bit#(32)) counterALimit <- mkReg(0);
   Reg#(Bit#(32)) counterA      <- mkReg(0);
   rule periodACount if (counterA < counterALimit);
      counterA <= counterA + 1;
      if (counterA == counterALimit - 1)
	 getElapsed.send();
   endrule

   method Action start(Bit#(32) periodA);
      counterA <= 0;
      counterALimit <= periodA;
      startElapsed.send();
   endmethod
   method ActionValue#(Bit#(32)) elapsedCycles();
      elapsedFifo.deq();
      return elapsedFifo.first();
   endmethod
endmodule

module mkTB(Empty);
   Clock c <- exposeCurrentClock();
   Reset r <- exposeCurrentReset();
   let fc <- mkFrequencyCounter(c,r);
   
   Stmt test =
   (seq
       delay(10);
       fc.start(10);
       action
	  let v <- fc.elapsedCycles;
	  $display(v);
       endaction
    endseq);
   mkAutoFSM(test);
endmodule