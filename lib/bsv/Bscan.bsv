
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
   provisos (Bits#(atype, asz), Bits#(dtype,dsz), Add#(1, a__, dsz));
   let asz = valueOf(asz);
   let dsz = valueOf(dsz);

   //Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

   BscanE2 bscan <- mkBscanE2(bus);
   Clock tck <- mkClockBUFG(clocked_by bscan.tck);
   Reset rst <- mkAsyncReset(2, defaultReset, tck);
   //SyncBitIfc#(Bit#(asz)) addr_jtag <- mkSyncBits(0, defaultClock, defaultReset, tck, rst);
   Wire#(Maybe#(BRAMRequest#(atype, dtype))) requestWire <- mkDWire(tagged Invalid, clocked_by tck, reset_by rst);
   Wire#(Maybe#(dtype)) responseWire <- mkDWire(tagged Invalid, clocked_by tck, reset_by rst);

   Reg#(Bit#(dsz)) shiftReg <- mkReg(0, clocked_by tck, reset_by rst);
   Reg#(Bit#(asz)) addrReg <- mkReg(0, clocked_by tck, reset_by rst);
   Reg#(Bool) capture_delay <- mkReg(False, clocked_by tck, reset_by rst);
   Reg#(Bool) selected_delay <- mkReg(False, clocked_by tck, reset_by rst);
   rule tdo;
       bscan.tdo(shiftReg[0]);
   endrule

   rule selected_rule;
       selected_delay <= bscan.sel() == 1;
       capture_delay <= bscan.sel() == 1 && bscan.capture() == 1;
   endrule

   //rule addr_clock_crossing;
       //addr_jtag.send(pack(addr));
   //endrule

   rule captureRule if (bscan.sel() == 1 && bscan.capture() == 1);
       requestWire <= tagged Valid BRAMRequest {write:False, responseOnWrite:False, address:unpack(addrReg), datain:?};
   endrule

   rule shiftrule if (bscan.sel() == 1 && bscan.shift() == 1);
       Bit#(dsz) shift = shiftReg;
       if (capture_delay) begin
	  Maybe#(dtype) m = responseWire;
	  let d = fromMaybe(unpack(0), m);
	  shift = pack(d);
       end
       shiftReg <= {bscan.tdi(), shift[dsz-1:1]};
   endrule

   rule updateRule if (bscan.sel() == 1 && bscan.update() == 1 && bscan.capture() == 0);
       requestWire <= tagged Valid (BRAMRequest {write:True, responseOnWrite:False, address:unpack(addrReg), datain:unpack(shiftReg)});
       let addr = addrReg + 1;
       if (!selected_delay)
	  addr = 0;  // first time USER1 selected, reset address
       addrReg <= addr;
   endrule

   interface BRAMClient bramClient;
      interface Get request;
	 method ActionValue#(BRAMRequest#(atype,dtype)) get() if (requestWire matches tagged Valid .req);
	    return req;
	 endmethod
      endinterface
      interface Put response;
	 method Action put(dtype d);
	    responseWire <= tagged Valid d;
	 endmethod
      endinterface
   endinterface
   interface Clock jtagClock = tck;
   interface Reset jtagReset = rst;
endmodule
