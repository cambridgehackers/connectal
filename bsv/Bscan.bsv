
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

import FIFOF::*;
import Clocks::*;
import BscanE2::*;
import GetPut::*;
import XilinxCells::*;

interface Bscan#(numeric type width);
   interface Put#(Bit#(width)) capture;
   interface Get#(Bit#(width)) update;
endinterface

module mkBscan#(Integer bus)(Bscan#(width));
   let width = valueOf(width);
   Clock defaultClk <- exposeCurrentClock();
   Reset defaultRst <- exposeCurrentReset();

   BscanE2 bscan <- mkBscanE2(bus);
   Clock tck <- mkClockBUFG(clocked_by bscan.tck);
   //Clock drck <- mkClockBUFG(clocked_by bscan.drck);
   // From: http://siliconexposed.blogspot.com/2013/10/soc-framework-part-5.html
   // SEL goes high whenever USERx is loaded into the instruction register,
   //     regardless of the test state machine's current state.
   // CAPTURE, RESET, RUNTEST, SHIFT, UPDATE are one-hot flags that go high
   //     when the corresponding DR state is active.
   //     When the state machine is in the IR shift path, all flags are held low.
   // TMS is of little practical use since the state machine is already implemented for you.
   // TCK provides direct access to the JTAG clock.
   //     (Be sure to create a timing constraint for any signals clocked by this net.)
   //     In my experience the Xilinx tools often do not recognize this signal
   //     as a clock and use high-skew local routing; manual insertion of a
   //     BUFG/BUFH is advised for optimal results.
   // DRCK is a gated version of TCK
   // TDI and TDO are connected to the corresponding JTAG pins when in the
   //     SHIFT-DR state. You can connect any fabric logic you want to them.
   // Example usage: http://www.pld.ttu.ee/~vadim/tty/IAY0570/video_pipeline/psram_app/program_rom.v
   // Example usage: http://ohm.bu.edu/~dean/G-2TrackerWORKING/uart_test.vhd
   Reset bscanRst = bscan.reset;

   Reg#(Bit#(width)) shiftReg <- mkReg('h1234dead, clocked_by tck); //, reset_by bscanRst);
   SyncFIFOIfc#(Bit#(width)) infifo <- mkSyncFIFO(2, defaultClk, defaultRst, tck);
   SyncFIFOIfc#(Bit#(width)) outfifo <- mkSyncFIFO(2, tck, bscanRst, defaultClk);

   rule captureRule if (bscan.capture() == 1 && bscan.sel() == 1);
      if (infifo.notEmpty()) begin
	 //shiftReg <= infifo.first();
	 infifo.deq();
      end
      //else
	 //shiftReg <= 0;
   endrule
   rule shift if (bscan.shift() == 1 && bscan.sel() == 1);
      bscan.tdo(shiftReg[0]);
      let v = (shiftReg >> 1);
      v[width-1] = bscan.tdi();
      shiftReg <= v;
   endrule
   rule updateRule if (bscan.update() == 1 && bscan.sel() == 1);
      if (outfifo.notFull()) begin
	 outfifo.enq(shiftReg);
      end
   endrule

   interface Put capture = toPut(infifo);
   interface Get update = toGet(outfifo);
endmodule
