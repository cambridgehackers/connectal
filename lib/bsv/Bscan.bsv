
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

`include "ConnectalProjectConfig.bsv"
import FIFOF::*;
import Clocks::*;
import Vector::*;
import BRAM::*;
import BscanE2::*;
import GetPut::*;
import XilinxCells::*;
import SyncBits::*;

// From: http://siliconexposed.blogspot.com/2013/10/soc-framework-part-5.html
// Example usage: http://www.pld.ttu.ee/~vadim/tty/IAY0570/video_pipeline/psram_app/program_rom.v
// Example usage: http://ohm.bu.edu/~dean/G-2TrackerWORKING/uart_test.vhd

interface BscanTop;
   interface Reset    rst;
   interface Clock    tck;
   method Bit#(1)     reset();
   method Bit#(1)     capture();
   method Bit#(1)     shift();
   method Bit#(1)     tdi();
   method Action      tdo(Bit#(1) v);
   method Bit#(1)     update();
   method Bool        first();
endinterface
`ifdef SIMULATION
module mkBscanTop#(Integer bus)(BscanTop);
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
   interface tck = defaultClock;
   interface rst = defaultReset;
   method reset();
       return 0;
   endmethod
   method tdi;
       return 0;
   endmethod
   method Action tdo(Bit#(1) v);
   endmethod
   method capture;
       return 0;
   endmethod
   method shift;
       return 0;
   endmethod
   method update;
       return 0;
   endmethod
   method first();
      return False;
   endmethod
endmodule
`else
module mkBscanTop#(Integer bus)(BscanTop);
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
   BscanE2 bscan <- mkBscanE2(bus);
   Clock mytck <- mkClockBUFG(clocked_by bscan.tck);
   Reset myrst <- mkAsyncReset(2, defaultReset, mytck);
   SyncBitIfc#(Bool) selected <- mkSyncBits(False, mytck, myrst, defaultClock, defaultReset);
   Reg#(Bool) selectdelay <- mkReg(False);

   rule updater;
       selected.send(bscan.sel() == 1);
   endrule
   rule writed;
       selectdelay <= selected.read();
   endrule

   interface tck = mytck;
   interface rst = myrst;
   method reset = bscan.reset;
   method tdi = bscan.tdi;
   method tdo = bscan.tdo;
   method capture;
       return bscan.sel & bscan.capture;
   endmethod
   method shift;
       return bscan.sel & bscan.shift;
   endmethod
   method update;
       return bscan.sel & bscan.update;
   endmethod
   method first();
      return selected.read() && !selectdelay;
   endmethod
endmodule
`endif

interface BscanLocal;
   interface Vector#(2, BscanTop) loc;
endinterface

module mkBscanLocal#(BscanTop bscan)(BscanLocal);
   Vector#(2, Wire#(Bit#(1))) tdo_wire <- replicateM(mkDWire(0));
   //Wire#(Bit#(1)) tdo_wire2 <- mkDWire(0);

   rule tdo_rule;
       bscan.tdo(tdo_wire[0] | tdo_wire[1]);
   endrule
   Vector#(2, BscanTop) vloc;
   for (Integer i = 0; i < 2; i = i + 1) begin
     vloc[i] =
      (interface BscanTop;
         method rst = bscan.rst;
         method tck = bscan.tck;
         method reset = bscan.reset;
         method capture = bscan.capture;
         method shift = bscan.shift;
         method tdi = bscan.tdi;
         method update = bscan.update;
         method first = bscan.first;
         method Action tdo(Bit#(1) v);
             tdo_wire[i] <= v;
         endmethod
      endinterface);
   end
   interface loc = vloc;
endmodule

interface BscanBram#(type atype, type dtype);
   interface BRAMClient#(atype, dtype) bramClient;
   method Bit#(1) data_out();
endinterface

module mkBscanBram#(Integer id, atype addr, BscanTop bscan)(BscanBram#(atype, dtype))
   provisos (Bits#(atype, asz), Bits#(dtype,dsz), Add#(1, a__, dsz));
   let asz = valueOf(asz);
   let dsz = valueOf(dsz);

   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

   Reg#(Bit#(asz)) addrReg <- mkReg(0);
   Reg#(Bool) readData <- mkReg(False);
   Reg#(Bool) firstItem <- mkReg(False);
   Reg#(Bool) selected <- mkReg(False);
   SyncBitIfc#(Bool) selectedj <- mkSyncBits(False, defaultClock, defaultReset, bscan.tck, bscan.rst);

   Reg#(Bit#(dsz)) shiftReg <- mkReg(0, clocked_by bscan.tck, reset_by bscan.rst);
   SyncBitIfc#(Bit#(dsz)) tojtag <- mkSyncBits(0, defaultClock, defaultReset, bscan.tck, bscan.rst);
   SyncBitIfc#(Bit#(dsz)) fromjtag <- mkSyncBits(0, bscan.tck, bscan.rst, defaultClock, defaultReset);
   SyncPulseIfc startWrite <- mkSyncHandshake(bscan.tck, bscan.rst, defaultClock);

   rule captureRule if(bscan.capture() == 1);
       shiftReg <= tojtag.read();
   endrule
   rule shiftRule if (bscan.shift() == 1);
       shiftReg <= { bscan.tdi(), shiftReg[dsz-1:1] };
   endrule
   rule updateRule if(bscan.update() == 1);
       startWrite.send();
       fromjtag.send(shiftReg);
   endrule

   rule firstRule if (bscan.first());
       firstItem <= True;
       selected <= False;
       selectedj.send(False);
       tojtag.send(0);
   endrule
   rule addrRule if (startWrite.pulse());
       let v = fromInteger(0);  // first time USER1, reset address
       if (firstItem) begin
           selected <= fromjtag.read() == fromInteger(id);
           selectedj.send(fromjtag.read() == fromInteger(id));
       end
       else
           v = addrReg + 1;
       addrReg <= v;
       firstItem <= False;
   endrule
   rule readdataRule;
       readData <= startWrite.pulse();
   endrule

   interface BRAMClient bramClient;
      interface Get request;
	 method ActionValue#(BRAMRequest#(atype,dtype)) get() if ((selected && startWrite.pulse()) || readData);
            return BRAMRequest {write:!readData, responseOnWrite:False, address:unpack(addrReg), datain:unpack(fromjtag.read())};
	 endmethod
      endinterface
      interface Put response;
	 method Action put(dtype d);
            tojtag.send(pack(d));
	 endmethod
      endinterface
   endinterface
   method Bit#(1) data_out();
      // the output lines are all OR'ed together when going back to the BSCAN core
      if (selectedj.read())
          return shiftReg[0];
      else
          return 0;
   endmethod
endmodule
