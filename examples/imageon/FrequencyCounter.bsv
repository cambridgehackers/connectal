import Clocks::*;
import FIFO::*;


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