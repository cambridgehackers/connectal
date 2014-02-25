
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
import SyncBits::*;

interface Bscan#(numeric type width);
   interface Put#(Bit#(width)) capture;
   interface Get#(Bit#(width)) update;
endinterface

// From: http://siliconexposed.blogspot.com/2013/10/soc-framework-part-5.html
// Example usage: http://www.pld.ttu.ee/~vadim/tty/IAY0570/video_pipeline/psram_app/program_rom.v
// Example usage: http://ohm.bu.edu/~dean/G-2TrackerWORKING/uart_test.vhd

module mkBscan#(Integer bus)(Bscan#(width));
   let width = valueOf(width);
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

   BscanE2 bscan <- mkBscanE2(bus);
       // SEL := (IR == 'USERx')
       // CAPTURE, RESET, RUNTEST, SHIFT, UPDATE: <name> := (TAP_state == <name>-DR)
       // TCK, TDI, TDO := corresponding JTAG pins
   Clock tck <- mkClockBUFG(clocked_by bscan.tck);
   Reset rst <- mkAsyncReset(2, defaultReset, tck);

   Reg#(Bit#(width)) shiftReg <- mkReg(0, clocked_by tck, reset_by rst);
   SyncFIFOIfc#(Bit#(width)) infifo <- mkSyncFIFO(2, defaultClock, defaultReset, tck);
   SyncFIFOIfc#(Bit#(width)) outfifo <- mkSyncFIFO(2, tck, rst, defaultClock);

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

interface BscanBram#(numeric type asz, numeric type dsz);
    interface BRAMServer#(Bit#(asz), Bit#(dsz)) server;
    method Bit#(asz) addr();
    method Bit#(4) debug;
endinterface

module mkBscanBram#(Integer bus, Integer memorySize)(BscanBram#(asz, dsz));
   let asz = valueOf(asz);
   let dsz = valueOf(dsz);

   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

   BscanE2 bscan <- mkBscanE2(bus);
   Clock tck <- mkClockBUFG(clocked_by bscan.tck);
   Reset rst <- mkAsyncReset(2, defaultReset, tck);

   BRAM_Configure bramCfg = defaultValue;
   bramCfg.memorySize = memorySize;
   bramCfg.latency = 1;
   BRAM2Port#(Bit#(asz), Bit#(dsz)) bram <- mkSyncBRAM2Server(bramCfg, defaultClock, defaultReset, tck, rst);

   Reg#(Bit#(dsz)) shiftReg <- mkReg(0, clocked_by tck, reset_by rst);
   Reg#(Bit#(asz)) addrReg <- mkReg(0, clocked_by tck, reset_by rst);
   Reg#(Bool) captured <- mkReg(False, clocked_by tck, reset_by rst);
   Reg#(Bool) selected_delay <- mkReg(False, clocked_by tck, reset_by rst);

   rule selected_rule;
       selected_delay <= bscan.sel() == 1;
   endrule

   rule reset_addr if (bscan.sel() == 1 && !selected_delay);
       addrReg <= 0;  // if we read USER2, reset address
   endrule

   rule captureRule if (bscan.capture() == 1 && bscan.sel() == 1);
       bram.portB.request.put(BRAMRequest {write:False, responseOnWrite:False, address:addrReg, datain:?});
       captured <= True;
   endrule

   rule shiftrule if (bscan.shift() == 1 && bscan.sel() == 1);
      Bit#(dsz) shift;
      if (captured)
         begin
         shift <- bram.portB.response.get();
         captured <= False;
         end
      else
	 shift = shiftReg;
      bscan.tdo(shift[0]);
      let v = (shift >> 1);
      v[dsz-1] = bscan.tdi();
      shiftReg <= v;
   endrule

   rule updateRule if (bscan.update() == 1 && bscan.sel() == 1);
      bram.portB.request.put(BRAMRequest {write:True, responseOnWrite:False, address:addrReg, datain:shiftReg});
      addrReg <= addrReg + 1;
   endrule

   interface server = bram.portA;
   method Bit#(4) debug;
       return {bscan.sel(), bscan.capture(), bscan.shift(), bscan.update()};
   endmethod
endmodule
