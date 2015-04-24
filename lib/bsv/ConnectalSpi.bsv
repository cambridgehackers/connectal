
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


import Clocks      :: *;
import GetPut      :: *;
import FIFOF       :: *;
import Probe       :: *;
import Connectable :: *;
import SpecialFIFOs:: *;
import SyncBits    :: *;
import StmtFSM     :: *;
import Assert      :: *;

(* always_enabled *)
interface SpiMasterPins;
    method Bit#(1) mosi();
    method Bit#(1) sel_n();
    method Action miso(Bit#(1) v);
    interface Clock clock;
    interface Clock deleteme_unused_clock;
    interface Reset deleteme_unused_reset;
endinterface: SpiMasterPins

(* always_enabled *)
interface SpiSlavePins;
    method Action mosi(Bit#(1) v);
    method Action sel_n(Bit#(1) v);
    method Bit#(1) miso();
    method Action clock(Bit#(1) v);
endinterface

interface SPIMaster#(type a);
   interface Put#(a) request;
   interface Get#(a) response;
   interface SpiMasterPins pins;
endinterface

interface SPISlave#(type a);
   interface Get#(a) request;
   interface Put#(a) response;
   interface SpiSlavePins pins;
endinterface

module mkSpiMasterShifter#(Bool invert_clk) (SPIMaster#(a)) provisos(Bits#(a,awidth),Add#(1,awidth1,awidth),Log#(awidth,logawidth));

   Clock defaultClock <- exposeCurrentClock;
   Reset defaultReset <- exposeCurrentReset;
   ClockDividerIfc clockInverter <- mkClockInverter;
   Clock spiClock = clockInverter.slowClock;
   Reset spiReset <-  mkAsyncResetFromCR(2, clockInverter.slowClock);
   Reg#(Bit#(awidth)) shiftreg <- mkReg(unpack(0));
   Reg#(Bit#(1)) selreg <- mkReg(1);
   Reg#(Bit#(TAdd#(logawidth,1))) countreg <- mkReg(0);
   FIFOF#(a) resultFifo <- mkFIFOF;

   Clock outputClock = invert_clk ? clockInverter.slowClock : defaultClock;
   Reset outputReset = defaultReset;
   ReadOnly#(Bit#(awidth)) sync_shiftreg <- mkNullCrossingWire(outputClock, shiftreg);

   Wire#(Bit#(1)) misoWire <- mkDWire(0);
   let verbose = False;
   
   rule running if (countreg > 0);
      countreg <= countreg - 1;
      Bit#(awidth) newshiftreg = { shiftreg[valueOf(awidth)-2:0], misoWire };
      if(verbose) $display("newshiftreg = %08h", newshiftreg);
      shiftreg <= newshiftreg;
      if (countreg == 1 && resultFifo.notFull) begin
	 resultFifo.enq(unpack(newshiftreg));
	 selreg <= 1;
      end
   endrule

   interface Put request;
      method Action put(a v) if (countreg == 0);
	 selreg <= 0;
	 shiftreg <= pack(v);
	 countreg <= fromInteger(valueOf(awidth));
      endmethod
   endinterface: request

   interface Get response;
      method ActionValue#(a) get();
	 resultFifo.deq;
	 return resultFifo.first;
      endmethod
   endinterface: response

   interface SpiMasterPins pins;
      method Bit#(1) mosi();
         return sync_shiftreg[valueOf(awidth)-1];
      endmethod
      method Bit#(1) sel_n();
	 return selreg;
      endmethod
      method Action miso(Bit#(1) v);
         misoWire <= v;
      endmethod
      interface Clock clock = outputClock;
      interface Clock deleteme_unused_clock = invert_clk ? defaultClock : clockInverter.slowClock;
      interface Reset deleteme_unused_reset = defaultReset;
   endinterface: pins
endmodule: mkSpiMasterShifter

module mkSPISlave(SPISlave#(a))
   provisos(Bits#(a,awidth));

endmodule

module mkSPIMaster#(Integer divisor, Bool invert_clk)(SPIMaster#(a)) provisos(Bits#(a,awidth),Add#(1,awidth1,awidth),Log#(awidth,logawidth));
   ClockDividerIfc clockDivider <- mkClockDivider(divisor);
   Reset slowReset <- mkAsyncResetFromCR(2, clockDivider.slowClock);
   SPIMaster#(a) spi <- mkSpiMasterShifter(invert_clk, clocked_by clockDivider.slowClock, reset_by slowReset);

   SyncFIFOIfc#(a) requestFifo <- mkSyncFIFOFromCC(1, clockDivider.slowClock);
   SyncFIFOIfc#(a) responseFifo <- mkSyncFIFOToCC(1, clockDivider.slowClock, slowReset);

   mkConnection(toGet(requestFifo), spi.request);
   mkConnection(spi.response, toPut(responseFifo));

   //interface spiClock = spi.spiClock;
   interface request = toPut(requestFifo);
   interface response = toGet(responseFifo);
   interface pins = spi.pins;
endmodule: mkSPIMaster

module mkSPI20(SPIMaster#(Bit#(20)));
   SPIMaster#(Bit#(20)) spi <- mkSPIMaster(200, True);
   return spi;
endmodule

module mkSpiTestBench(Empty);
   Clock defaultClock <- exposeCurrentClock;
   Reset defaultReset <- exposeCurrentReset;

   Bit#(20) slaveV = 20'h96ed5;
   Bit#(20) masterV = 20'h8baeb;
   let verbose = False;

   SPIMaster#(Bit#(20)) spi <- mkSPIMaster(4, False);
   Reg#(Bit#(20)) slaveCount <- mkReg(20, clocked_by spi.pins.clock, reset_by spi.pins.deleteme_unused_reset);
   Reg#(Bit#(20)) slaveValue <- mkReg(slaveV, clocked_by spi.pins.clock, reset_by spi.pins.deleteme_unused_reset);
   Reg#(Bit#(20)) responseValue <- mkReg(0, clocked_by spi.pins.clock, reset_by spi.pins.deleteme_unused_reset);
   SyncBitIfc#(Bit#(1)) sync_sel_n <- mkSyncBits(0, defaultClock, defaultReset, spi.pins.clock, spi.pins.deleteme_unused_reset);

   Probe#(Bit#(1)) probeSelN <- mkProbe(clocked_by spi.pins.clock, reset_by spi.pins.deleteme_unused_reset);
   Probe#(Bit#(1)) probeMiso <- mkProbe(clocked_by spi.pins.clock, reset_by spi.pins.deleteme_unused_reset);
   Probe#(Bit#(1)) probeMosi <- mkProbe(clocked_by spi.pins.clock, reset_by spi.pins.deleteme_unused_reset);

   rule probePins;
      probeSelN <= spi.pins.sel_n;
      probeMosi <= spi.pins.mosi;
   endrule

   rule slaveIn if (spi.pins.sel_n == 0);
      slaveCount <= slaveCount - 1;
      slaveValue <= (slaveValue << 1);
   endrule

   rule miso if (spi.pins.sel_n == 0);
      probeMiso <= slaveValue[19];
      spi.pins.miso(slaveValue[19]);
   endrule

   rule spipins if (spi.pins.sel_n == 0);
      if(verbose) $display("miso=%d mosi=%d sel=%d", slaveValue[19], spi.pins.mosi, sync_sel_n.read());
      responseValue <= { responseValue[18:0], spi.pins.mosi };
   endrule

   rule displaySlaveValue if (slaveCount == 0);
      if(verbose) $display("slave received %h", responseValue);
      dynamicAssert(responseValue == masterV, "wrong value received by slave");
   endrule

   rule finished;
      let result <- spi.response.get();
      if(verbose) $display("master received %h", result);
      dynamicAssert(result == slaveV, "wrong value received by master");
      $finish(0);
   endrule

   let once <- mkOnce(action
      if(verbose) $display("master sending %h; slave sending %h", masterV, slaveV);
      $dumpvars();
      spi.request.put(masterV);
      endaction);
   rule foobar;
      once.start();
   endrule

endmodule
