
// Copyright (c) 2013-2014 Quanta Research Cambridge, Inc.

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


import Gearbox :: *;
import Clocks  :: *;
import Vector  :: *;

module mkGearboxTb(Empty);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    ClockDividerIfc clockDivider <- mkClockDivider(4);
    Reset slowReset <- mkAsyncReset(2, defaultReset, clockDivider.slowClock);
    
    Gearbox#(4,1,Bit#(2)) gearbox <- mkNto1Gearbox(clockDivider.slowClock, slowReset, clockDivider.fastClock, defaultReset);

    Reg#(Bit#(2)) state <- mkReg(0, clocked_by clockDivider.slowClock, reset_by slowReset);
    Reg#(Bit#(22)) timeReg <- mkReg(0);

    rule clock;
        $display("cycle=%d", timeReg);
	timeReg <= timeReg+1;
    endrule
    rule startGearbox if (state == 0);
       Vector#(4,Bit#(2)) in;
       in[0] = 0;
       in[1] = 1;
       in[2] = 2;
       in[3] = 3;
       $display("gearbox.enq(%h)", in);
       gearbox.enq(in);
       state <= 1;
    endrule
    rule state1 if (state == 1);
       Vector#(4,Bit#(2)) in = unpack(8'b11100100);
       gearbox.enq(in);
       $display("gearbox.enq(%h)", in);
       state <= 2;
    endrule
   rule gearboxData;
      let v = gearbox.first;
      gearbox.deq;
      $display("gearbox.first = %h", v);
   endrule
   rule state2 if (state == 2);
      Vector#(4,Bit#(2)) in = unpack(8'h0);
      gearbox.enq(in);
      $finish(0);
   endrule
endmodule
