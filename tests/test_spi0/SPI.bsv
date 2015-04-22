
// Copyright (c) 2015 Quanta Research Cambridge, Inc.

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

import Vector::*;
import ConnectalXilinxCells::*;
import PPS7LIB::*;
import FrequencyCounter::*;
import ConnectalClocks::*;
import XilinxCells::*;
import Clocks::*;
import BRAMFIFO::*;
import FIFOF::*;

interface SPIRequest;
   method Action cnt_cycle_req(Bit#(32) v);
   method Action set_spew_en(Bit#(1) v);
   method Action set_clk_inv(Bit#(1) v);
   method Action set_spew_src(Bit#(1) v);
endinterface

interface SPIResponse;
   method Action cnt_cycle_resp(Bit#(32) v);
   method Action emio_sample(Bit#(32) v);
   method Action spi_word(Bit#(32) v);
endinterface

interface Controller;
   interface SPIRequest req;
endinterface

module mkController#(SPIResponse ind, Pps7Emiospi spi)(Controller);
   
   B2C1 b2c <- mkB2C1();
   Clock def_clk <- exposeCurrentClock;
   Clock spi_clk <- mkClockBUFG(clocked_by b2c.c);
   Reset spi_rst <- mkAsyncResetFromCR(2, spi_clk);

   Reg#(Bit#(32)) shift_reg <- mkReg(0, clocked_by spi_clk, reset_by spi_rst);
   Reg#(Bit#(5))  cnt_reg <- mkReg(0, clocked_by spi_clk, reset_by spi_rst);

   ReadOnly#(Bit#(1)) mo_sync     <- mkNullCrossingWire(spi_clk, spi.mo);
   ReadOnly#(Bit#(1)) motn_sync   <- mkNullCrossingWire(spi_clk, spi.motn);
   ReadOnly#(Bit#(3)) sson_sync   <- mkNullCrossingWire(spi_clk, spi.sson);
   ReadOnly#(Bit#(1)) ssntn_sync  <- mkNullCrossingWire(spi_clk, spi.ssntn);
   ReadOnly#(Bit#(1)) sclko_sync  <- mkNullCrossingWire(spi_clk, spi.sclko);
   ReadOnly#(Bit#(1)) sclktn_sync <- mkNullCrossingWire(spi_clk, spi.sclktn);
   ReadOnly#(Bit#(1)) miso_sync   <- mkNullCrossingWire(def_clk, shift_reg[31]);
   
   Reg#(Bit#(1)) spew_src <- mkReg(0);
   Reg#(Bit#(1)) clk_inv <- mkReg(0);
   Reg#(Bit#(1)) spew_en <- mkSyncRegFromCC(0, spi_clk);
   FrequencyCounter fc <- mkFrequencyCounter(spi_clk, spi_rst);
   SyncFIFOIfc#(Bit#(32)) req_fifo <- mkSyncFIFOToCC(2, spi_clk, spi_rst);
   SyncFIFOIfc#(Bit#(32)) spew_fifo <- mkSyncBRAMFIFOToCC(128, spi_clk, spi_rst);

   (* fire_when_enabled *)
   rule connect_to_ps7;
      b2c.inputclock(clk_inv ^ (spi.sclko & ~spi.sclktn));
      spi.mi(miso_sync);
      spi.sclki(0);
      spi.si(0);
      spi.ssin(1);
   endrule
   
   let mosi_signal = mo_sync & ~motn_sync;
   let sson_signal = sson_sync[0] | ssntn_sync;
   rule mosi_rule if (sson_signal == 0);
      shift_reg <= {shift_reg[30:0],mosi_signal};
      cnt_reg <= cnt_reg+1;
      if (cnt_reg == maxBound) req_fifo.enq(shift_reg);
   endrule

   rule cnt_cycle_resp_rule;
      let v <- fc.elapsedCycles;
      ind.cnt_cycle_resp(v);
   endrule

   rule drain_req_fifo;
      ind.spi_word(req_fifo.first);
      req_fifo.deq;
   endrule
   
   rule emio_sample_rule_a if (spew_en == 1);
      spew_fifo.enq({0, mo_sync, motn_sync, sson_sync, ssntn_sync, sclko_sync, sclktn_sync, cnt_reg});
   endrule

   rule emio_sample_rule_b;
      if (spew_src == 1) begin
	 ind.emio_sample({0, spi.mo, spi.motn, spi.sson, spi.ssntn, spi.sclko, spi.sclktn, 5'b00000});
      end
      else begin
	 ind.emio_sample(spew_fifo.first);
	 spew_fifo.deq;
      end
   endrule
   
   interface SPIRequest req;
      method Action cnt_cycle_req(Bit#(32) v);
	 fc.start(v);
      endmethod
      method Action set_spew_en(Bit#(1) v);
	 spew_en <= v;
      endmethod
      method Action set_clk_inv(Bit#(1) v);
	 clk_inv <= v;
      endmethod
      method Action set_spew_src(Bit#(1) v);
	 spew_src <= v;
      endmethod
   endinterface

endmodule


