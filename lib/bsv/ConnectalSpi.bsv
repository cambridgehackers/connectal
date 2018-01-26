
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
import XilinxCells :: *;
import Vector      :: *;
import ConnectalClocks :: *;

(* always_enabled *)
interface SpiMasterPins#(numeric type num_cs);
    method Bit#(1) mosi();
    method Bit#(num_cs) sel_n();
    method Action miso(Bit#(1) v);
    interface Clock clock;
    interface Clock deleteme_unused_clock;
    interface Reset deleteme_unused_reset;
endinterface: SpiMasterPins

(* always_enabled *)
interface SpiSlavePins#(numeric type num_cs);
    method Action mosi(Bit#(1) v);
    method Action sel_n(Bit#(num_cs) v);
    method Bit#(1) miso();
    method Action clock(Bit#(1) v);
    interface Clock deleteme_unused_clock;
    interface Reset deleteme_unused_reset;
endinterface

interface SPIMaster#(type a, numeric type num_cs);
   interface Vector#(num_cs, Put#(a)) request;
   interface Vector#(num_cs, Get#(a)) response;
   interface SpiMasterPins#(num_cs) pins;
endinterface

interface SPISlave#(type a, numeric type num_cs);
   interface Vector#(num_cs, Get#(a)) request;
   interface Vector#(num_cs, Put#(a)) response;
   interface SpiSlavePins#(num_cs) pins;
endinterface

module mkSpiMasterShifter#(Bool invert_clk) (SPIMaster#(a,num_cs)) provisos(Bits#(a,awidth),Add#(1,awidth1,awidth),Log#(awidth,logawidth));

   Clock defaultClock <- exposeCurrentClock;
   Reset defaultReset <- exposeCurrentReset;
   ClockDividerIfc clockInverter <- mkClockInverter;
   Clock spiClock = clockInverter.slowClock;
   Reset spiReset <-  mkAsyncResetFromCR(2, clockInverter.slowClock);
   Reg#(Bit#(awidth)) shiftreg <- mkReg(unpack(0));
   Reg#(Bit#(num_cs)) selreg <- mkReg(maxBound);
   Reg#(Bit#(TAdd#(logawidth,1))) countreg <- mkReg(0);
   Reg#(Bit#(TLog#(num_cs))) ifcnumreg <- mkReg(0);
   Vector#(num_cs, FIFOF#(a)) requestFifo <- replicateM(mkFIFOF);
   Vector#(num_cs, FIFOF#(a)) resultFifo <- replicateM(mkFIFOF);

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
      if (countreg == 1 && resultFifo[ifcnumreg].notFull) begin
	 resultFifo[ifcnumreg].enq(unpack(newshiftreg));
	 selreg <= maxBound;
      end
   endrule

   for (Integer i = 0; i < valueOf(num_cs); i = i + 1)
      rule start_request if (countreg == 0);
	 let v <- toGet(requestFifo[i]).get();
	 ifcnumreg <= fromInteger(i);
	 selreg <= ~(1 << fromInteger(i));
	 shiftreg <= pack(v);
	 countreg <= fromInteger(valueOf(awidth));
      endrule

   interface Vector request = map(toPut, requestFifo);
   interface Vector response = map(toGet, resultFifo);

   interface SpiMasterPins pins;
      method Bit#(1) mosi();
         return sync_shiftreg[valueOf(awidth)-1];
      endmethod
      method Bit#(num_cs) sel_n();
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

module mkSpiSlaveShifter#(ReadOnly#(Bit#(1)) mosi,
			  ReadOnly#(Bit#(num_cs)) seln)(SPISlave#(a, num_cs))
   provisos(Bits#(a,awidth),
	    Add#(__a,1,awidth),
	    Add#(TLog#(awidth),1,cwidth));
   
   let awidth = valueOf(awidth);
   Reg#(Bit#(awidth)) shift_reg <- mkReg(0);
   Reg#(Bit#(cwidth)) cnt_reg <- mkReg(0);

   Vector#(num_cs, FIFOF#(a)) req_fifo <- replicateM(mkFIFOF);
   Vector#(num_cs, FIFOF#(a)) resp_fifo <- replicateM(mkFIFOF);
   
   for (Integer i = 0; i < valueOf(num_cs); i = i + 1)
      (* fire_when_enabled *)
      rule mosi_rule if (seln._read[i] == 0);
	 let s = shift_reg;
	 if (cnt_reg == 0 && resp_fifo[i].notEmpty) begin
	    s = pack(resp_fifo[i].first);
	    resp_fifo[0].deq;
	 end
	 let new_s = {s[awidth-2:0],mosi._read};
	 if (cnt_reg+1 == fromInteger(awidth) && req_fifo[i].notFull) begin
	    cnt_reg <= 0;
	    req_fifo[i].enq(unpack(new_s));
	 end
	 else begin
	    cnt_reg <= cnt_reg+1;
	    shift_reg <= new_s;
	 end
      endrule

   interface request = map(toGet, req_fifo);
   interface response = map(toPut, resp_fifo);
   interface SpiSlavePins pins;
      method Bit#(1) miso();
	 return shift_reg[awidth-1];
      endmethod
   endinterface
   
endmodule : mkSpiSlaveShifter

module mkSPISlave(SPISlave#(a, num_cs))
   provisos(Bits#(a,awidth),
	    Add#(__a,1,awidth));

   B2C1 b2c <- mkB2C1();
   Clock def_clk <- exposeCurrentClock;
   Clock spi_clk <- mkClockBUFG(clocked_by b2c.c);
   Reset spi_rst <- mkAsyncResetFromCR(2, spi_clk);

   Wire#(Bit#(1)) mosi_wire <- mkDWire(0);
   Wire#(Bit#(num_cs)) seln_wire <- mkDWire(1);
   Wire#(Bit#(1)) clk_wire  <- mkDWire(0);
   
   ReadOnly#(Bit#(1)) mosi_sync <- mkNullCrossingWire(spi_clk, mosi_wire);
   ReadOnly#(Bit#(num_cs)) seln_sync <- mkNullCrossingWire(spi_clk, seln_wire);
   SPISlave#(a,num_cs) shifter <- mkSpiSlaveShifter(mosi_sync, seln_sync, clocked_by spi_clk, reset_by spi_rst);
   ReadOnly#(Bit#(1)) miso_sync <- mkNullCrossingWire(def_clk, shifter.pins.miso);

   Vector#(num_cs, SyncFIFOIfc#(a)) responseFifo <- replicateM(mkSyncFIFOFromCC(1, spi_clk));
   Vector#(num_cs, SyncFIFOIfc#(a)) requestFifo  <- replicateM(mkSyncFIFOToCC(1, spi_clk, spi_rst));
   zipWithM(mkConnection, map(toPut, requestFifo),  shifter.request);
   zipWithM(mkConnection, map(toGet, responseFifo), shifter.response);
   
   rule clk_rule;
      b2c.inputclock(clk_wire);
   endrule
   
   interface request = map(toGet, requestFifo); 
   interface response = map(toPut, responseFifo); 
   interface SpiSlavePins pins;
      method Action mosi(Bit#(1) v);
	 mosi_wire._write(v);
      endmethod
      method Action sel_n(Bit#(num_cs) v);
	 seln_wire._write(v);
      endmethod
      method Bit#(1) miso();
	 return miso_sync._read();
      endmethod
      method Action clock(Bit#(1) v);
	 clk_wire._write(v);
      endmethod
      interface Clock deleteme_unused_clock = spi_clk;
      interface Reset deleteme_unused_reset = spi_rst;
   endinterface: pins
endmodule : mkSPISlave

module mkSPIMaster#(Integer divisor, Bool invert_clk)(SPIMaster#(a,num_cs))
   provisos(Bits#(a,awidth),Add#(1,awidth1,awidth),Log#(awidth,logawidth));
   ClockDividerIfc clockDivider <- mkClockDivider(divisor);
   Reset slowReset <- mkAsyncResetFromCR(2, clockDivider.slowClock);
   SPIMaster#(a, num_cs) spi <- mkSpiMasterShifter(invert_clk, clocked_by clockDivider.slowClock, reset_by slowReset);

   Vector#(num_cs, SyncFIFOIfc#(a)) requestFifo <- replicateM(mkSyncFIFOFromCC(1, clockDivider.slowClock));
   Vector#(num_cs, SyncFIFOIfc#(a)) responseFifo <- replicateM(mkSyncFIFOToCC(1, clockDivider.slowClock, slowReset));

   zipWithM(mkConnection, map(toGet, requestFifo), spi.request);
   zipWithM(mkConnection, spi.response, map(toPut, responseFifo));

   //interface spiClock = spi.spiClock;
   interface request = map(toPut, requestFifo);
   interface response = map(toGet, responseFifo);
   interface pins = spi.pins;
endmodule: mkSPIMaster

module mkSPI20(SPIMaster#(Bit#(20),1));
   SPIMaster#(Bit#(20),1) spi <- mkSPIMaster(200, True);
   return spi;
endmodule

module mkSpiTestBench(Empty);

   Clock defaultClock <- exposeCurrentClock;
   Reset defaultReset <- exposeCurrentReset;

   Bit#(20) slaveV = 20'h96ed5;
   Bit#(20) masterV = 20'h8baeb;
   let verbose = False;

   SPIMaster#(Bit#(20),1) spi <- mkSPIMaster(4, False);
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
      let result <- spi.response[0].get();
      if(verbose) $display("master received %h", result);
      dynamicAssert(result == slaveV, "wrong value received by master");
      $finish(0);
   endrule

   let once <- mkOnce(action
      if(verbose) $display("master sending %h; slave sending %h", masterV, slaveV);
      $dumpvars();
      spi.request[0].put(masterV);
      endaction);
   rule foobar;
      once.start();
   endrule

endmodule
