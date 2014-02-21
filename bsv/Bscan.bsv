
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
import BRAM::*;
import BscanE2::*;
import GetPut::*;
import XilinxCells::*;

interface Bscan#(numeric type width);
   interface Put#(Bit#(width)) capture;
   interface Get#(Bit#(width)) update;
endinterface

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

module mkBscan#(Integer bus)(Bscan#(width));
   let width = valueOf(width);
   Clock defaultClk <- exposeCurrentClock();
   Reset defaultRst <- exposeCurrentReset();

   BscanE2 bscan <- mkBscanE2(bus);
   Clock tck <- mkClockBUFG(clocked_by bscan.tck);
   Reset rst <- mkAsyncReset(2, defaultRst, tck);

   Reg#(Bit#(width)) shiftReg <- mkReg(0, clocked_by tck, reset_by rst);
   SyncFIFOIfc#(Bit#(width)) infifo <- mkSyncFIFO(2, defaultClk, defaultRst, tck);
   SyncFIFOIfc#(Bit#(width)) outfifo <- mkSyncFIFO(2, tck, rst, defaultClk);

   rule captureRule if (bscan.capture() == 1 && bscan.sel() == 1);
      if (infifo.notEmpty()) begin
	 //shiftReg <= tagged Valid infifo.first();
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
      //if (outfifo.notFull()) begin
      //outfifo.enq(shiftReg);
      //end
   endrule

   interface Put capture = toPut(infifo);
   interface Get update = toGet(outfifo);
endmodule

module mkBscanBram#(Integer bus, Integer memorySize)(BRAMServer#(Bit#(asz), Bit#(dsz)));
   let asz = valueOf(asz);
   let dsz = valueOf(dsz);

   Clock defaultClk <- exposeCurrentClock();
   Reset defaultRst <- exposeCurrentReset();

   BscanE2 bscan1 <- mkBscanE2(bus);
   Clock tck1 <- mkClockBUFG(clocked_by bscan1.tck);
   Reset rst1 <- mkAsyncReset(2, defaultRst, tck1);

   BscanE2 bscan2 <- mkBscanE2(bus+1);
   Clock tck2 <- mkClockBUFG(clocked_by bscan2.tck);
   Reset rst2 <- mkAsyncReset(2, defaultRst, tck2);
   Reg#(Bit#(asz)) addrReg <- mkReg(0, clocked_by tck1, reset_by rst1);

   BRAM_Configure bramCfg = defaultValue;
   bramCfg.memorySize = memorySize;
   BRAM2Port#(Bit#(asz), Bit#(dsz)) bram <- mkSyncBRAM2Server(bramCfg, defaultClk, defaultRst, tck1, rst1);

   Reg#(Bit#(asz)) shiftReg1 <- mkReg(0, clocked_by tck1, reset_by rst1);
   rule captureRule1 if (bscan1.capture() == 1 && bscan1.sel() == 1);
      shiftReg1 <= addrReg;
   endrule
   rule shift1 if (bscan1.shift() == 1 && bscan1.sel() == 1);
      bscan1.tdo(shiftReg1[0]);
      let v = (shiftReg1 >> 1);
      v[asz-1] = bscan1.tdi();
      shiftReg1 <= v;
   endrule
   rule updateRule1 if (bscan1.update() == 1 && bscan1.sel() == 1);
      addrReg <= shiftReg1;
      bram.portB.request.put(BRAMRequest {write:False, responseOnWrite:False, address:addrReg, datain:?});
   endrule

   Reg#(Bit#(dsz)) dataReg1 <- mkReg(0, clocked_by tck1, reset_by rst1);
   rule bramResp;
      let v <- bram.portB.response.get();
      dataReg1 <= v;
   endrule


   ReadOnly#(Bit#(dsz)) dataCross <- mkNullCrossingWire(tck2, dataReg1, clocked_by tck1, reset_by rst1);

   Reg#(Bit#(dsz)) shiftReg2 <- mkReg(0, clocked_by tck2, reset_by rst2);

   rule captureRule2 if (bscan2.capture() == 1 && bscan2.sel() == 1);
      shiftReg2 <= dataCross;
   endrule
   rule shift2 if (bscan2.shift() == 1 && bscan2.sel() == 1);
      bscan2.tdo(shiftReg2[0]);
      let v = (shiftReg2 >> 1);
      v[dsz-1] = bscan2.tdi();
      shiftReg2 <= v;
   endrule
   rule updateRule2 if (bscan2.update() == 1 && bscan2.sel() == 1);
   endrule


   return bram.portA;
endmodule
