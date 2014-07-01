
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

// From: http://siliconexposed.blogspot.com/2013/10/soc-framework-part-5.html
// Example usage: http://www.pld.ttu.ee/~vadim/tty/IAY0570/video_pipeline/psram_app/program_rom.v
// Example usage: http://ohm.bu.edu/~dean/G-2TrackerWORKING/uart_test.vhd

interface BscanBram#(type atype, type dtype);
   interface Clock jtagClock;
   interface Reset jtagReset;
   interface BRAMClient#(atype, dtype) bramClient;
endinterface

module mkBscanBram#(Integer bus, atype addr)(BscanBram#(atype, dtype))
   provisos (Bits#(atype, asz), Bits#(dtype,dsz), Add#(1, a__, dsz)
,Add#(b__, asz, dsz)
);
   let asz = valueOf(asz);
   let dsz = valueOf(dsz);

   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
   BscanE2 bscan <- mkBscanE2(bus);
   Clock tck <- mkClockBUFG(clocked_by bscan.tck);
   Reset rst <- mkAsyncReset(2, defaultReset, tck);

   Reg#(Bit#(asz)) addrReg <- mkReg(0);
   Reg#(Bit#(dsz)) fromBram <- mkReg(0);
   Reg#(Bool) selectdelay <- mkReg(False);
   Reg#(Bool) readData <- mkReg(False);

   Reg#(Bit#(dsz)) shiftReg <- mkReg(0, clocked_by tck, reset_by rst);
   SyncBitIfc#(Bit#(dsz)) tojtag <- mkSyncBits(0, defaultClock, defaultReset, tck, rst);
   SyncBitIfc#(Bit#(dsz)) fromjtag <- mkSyncBits(0, tck, rst, defaultClock, defaultReset);
   SyncBitIfc#(Bool) selected <- mkSyncBits(False, tck, rst, defaultClock, defaultReset);
   SyncPulseIfc startWrite <- mkSyncHandshake(tck, rst, defaultClock);

   let thisActive = bscan.sel() == 1;
   let readNext = startWrite.pulse() || (selected.read() && !selectdelay);

   rule fromj;
       fromjtag.send(shiftReg);
   endrule

   rule toj;
       tojtag.send(fromBram);
   endrule

   rule updater;
       selected.send(thisActive);
   endrule
   rule writed;
       selectdelay <= selected.read();
   endrule

   rule capturer if(//thisActive && 
bscan.capture() == 1);
       shiftReg <= tojtag.read();
   endrule
   rule sendwrite if(thisActive && bscan.update() == 1);
       startWrite.send();
   endrule
   rule shiftrule if (//thisActive && 
bscan.shift() == 1);
       shiftReg <= { bscan.tdi(), shiftReg[dsz-1:1] };
   endrule
   rule tdo;
      bscan.tdo(shiftReg[0]);
   endrule

   rule addrRule if (readNext);
       let v = fromInteger(0);  // first time USER1 selected, reset address
       if (startWrite.pulse())
           v = addrReg + 1;
       addrReg <= v;
   endrule
   rule readClear;
       readData <= readNext;
   endrule

   interface BRAMClient bramClient;
      interface Get request;
	 method ActionValue#(BRAMRequest#(atype,dtype)) get() if (startWrite.pulse() || readData);
            return BRAMRequest {write:!readData, responseOnWrite:False, address:unpack(addrReg), datain:unpack(fromjtag.read())};
	 endmethod
      endinterface
      interface Put response;
	 method Action put(dtype d);
	    fromBram <= pack(d);
	 endmethod
      endinterface
   endinterface
   interface Clock jtagClock = defaultClock;
   interface Reset jtagReset = defaultReset;
endmodule
