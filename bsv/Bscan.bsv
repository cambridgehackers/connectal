
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
// Example usage: http://www.pld.ttu.ee/~vadim/tty/IAY0570/video_pipeline/psram_app/program_rom.v
// Example usage: http://ohm.bu.edu/~dean/G-2TrackerWORKING/uart_test.vhd

module mkBscan#(Integer bus)(Bscan#(width));
   let width = valueOf(width);
   Clock defaultClk <- exposeCurrentClock();
   Reset defaultRst <- exposeCurrentReset();

   BscanE2 bscan <- mkBscanE2(bus);
       // SEL := (IR == 'USERx')
       // CAPTURE, RESET, RUNTEST, SHIFT, UPDATE: <name> := (TAP_state == <name>-DR)
       // TCK, TDI, TDO := corresponding JTAG pins
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
   Reg#(Bit#(asz)) addrReg1 <- mkReg(0, clocked_by tck1, reset_by rst1);

   Reg#(Bit#(asz)) shiftReg1 <- mkReg(0, clocked_by tck1, reset_by rst1);
   rule captureRule1 if (bscan1.capture() == 1 && bscan1.sel() == 1);
      shiftReg1 <= addrReg1;
   endrule
   rule shift1 if (bscan1.shift() == 1 && bscan1.sel() == 1);
      bscan1.tdo(shiftReg1[0]);
      let v = (shiftReg1 >> 1);
      v[asz-1] = bscan1.tdi();
      shiftReg1 <= v;
   endrule
   rule updateRule1 if (bscan1.update() == 1 && bscan1.sel() == 1);
      addrReg1 <= shiftReg1;
   endrule

   BRAM_Configure bramCfg = defaultValue;
   bramCfg.memorySize = memorySize;
   bramCfg.latency = 1;
   BRAM2Port#(Bit#(asz), Bit#(dsz)) bram <- mkSyncBRAM2Server(bramCfg, defaultClk, defaultRst, tck2, rst2);


   Reg#(Bit#(dsz)) shiftReg2 <- mkReg(0, clocked_by tck2, reset_by rst2);
   Reg#(Bit#(asz)) addrReg2 <- mkReg(0, clocked_by tck2, reset_by rst2);
   ReadOnly#(Bit#(asz)) addrCross <- mkNullCrossingWire(tck2, addrReg1, clocked_by tck1, reset_by rst1);
   rule updateAddr2 if (bscan2.sel() == 0);
      addrReg2 <= addrCross;
   endrule


   Reg#(Bool) captured <- mkReg(False, clocked_by tck2, reset_by rst2);
   rule captureRule2 if (bscan2.capture() == 1 && bscan2.sel() == 1);
      bram.portB.request.put(BRAMRequest {write:False, responseOnWrite:False, address:addrReg2, datain:?});
      captured <= True;
   endrule
   rule shift2 if (bscan2.shift() == 1 && bscan2.sel() == 1);
      let shift = shiftReg2;
      if (captured) begin
	 shift <- bram.portB.response.get();
	 captured <= False;
      end
      bscan2.tdo(shift[0]);
      let v = (shift >> 1);
      v[dsz-1] = bscan2.tdi();
      shiftReg2 <= v;
   endrule
   rule updateRule2 if (bscan2.update() == 1 && bscan2.sel() == 1);
   endrule


   return bram.portA;
endmodule
