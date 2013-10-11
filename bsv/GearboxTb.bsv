

import Gearbox :: *;
import Clocks  :: *;
import Vector  :: *;

module mkGearboxTb(Empty);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    ClockDividerIfc clockDivider <- mkClockDivider(4);
    Reset slowReset <- mkAsyncReset(2, defaultReset, clockDivider.slowClock);
    
    Gearbox#(4,1,Bit#(2)) gearbox <- mkNto1Gearbox(clockDivider.fastClock, defaultReset, clockDivider.slowClock, slowReset);

    Reg#(Bit#(2)) state <- mkReg(0);

    rule startGearbox if (state == 0);
       Vector#(4,Bit#(2)) in;
       in[0] = 0;
       in[1] = 1;
       in[2] = 2;
       in[3] = 3;
       gearbox.enq(in);
       state <= 1;
    endrule
    rule state1 if (state == 1);
       Vector#(4,Bit#(2)) in = unpack(8'b11100100);
       gearbox.enq(in);
       state <= 2;
    endrule
   rule gearboxData;
      let v = gearbox.first;
      gearbox.deq;
      $display("v = %h", v);
   endrule
endmodule