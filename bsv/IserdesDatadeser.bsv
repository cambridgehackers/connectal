
// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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
import Clocks :: *;
import XilinxCells::*;
import XbsvXilinxCells::*;

interface IserdesDatadeser;
   method Action                 ibufds_out(Bit#(1) v);
   method Action                 align_start(Bit#(1) v);
   method Bit#(1)                align_busy();
   method Bit#(1)                aligned();
   method Bit#(1)                sampleinfirstbit();
   method Bit#(1)                sampleinlastbit();
   method Bit#(1)                sampleinotherbit();
   method Action                 autoalign(Bit#(1) v);
   method Action                 training(Bit#(10) v);
   method Action                 manual_tap(Bit#(10) v);
   method Action                 rden(Bit#(1) v);
   method Action                 delay_wren(Bit#(1) v);
   method Action                 fifo_wren(Bit#(1) v);
   method Action                 reset(Bit#(1) v);
   method Bit#(1)                empty();
   method Bit#(10)               dataout();
endinterface: IserdesDatadeser

import "BVI" iserdes_datadeser = 
module mkIserdesbvi#(Clock clkdiv, Clock serdest)(IserdesDatadeser);
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

   input_clock clk (CLK) = serdest;
   input_clock clkdiv (CLKDIV) = clkdiv;
   default_clock clock(CLOCK);
       method              ibufds_out(IBUFDS_OUT) enable((*inhigh*) en0); // clocked_by () reset_by ()
      method                  align_start(ALIGN_START) enable((*inhigh*) en1) clocked_by (clock);
      method ALIGN_BUSY       align_busy() clocked_by (clock);
      method ALIGNED          aligned() clocked_by (clock);
      method SAMPLEINFIRSTBIT sampleinfirstbit() clocked_by (clock);
      method SAMPLEINLASTBIT  sampleinlastbit() clocked_by (clock);
      method SAMPLEINOTHERBIT sampleinotherbit() clocked_by (clock);
      method                  autoalign(AUTOALIGN) enable((*inhigh*) en7) clocked_by (clock);
      method                  training(TRAINING) enable((*inhigh*) en8) clocked_by (clock);
      method                  manual_tap(MANUAL_TAP) enable((*inhigh*) en9) clocked_by (clock);
      method                  rden(FIFO_RDEN) enable((*inhigh*) en12) clocked_by (clock);
      method                  fifo_wren(FIFO_WREN) enable((*inhigh*) en10) clocked_by (clkdiv);
      method                  delay_wren(DELAY_WREN) enable((*inhigh*) en11) clocked_by (clkdiv);
      method                  reset(RESET) enable((*inhigh*) en16) clocked_by (clkdiv);
      method FIFO_EMPTY    empty() clocked_by (clock);
      method FIFO_DATAOUT  dataout() clocked_by(clock);
   schedule (fifo_wren, reset, delay_wren) CF (fifo_wren, reset, delay_wren);
   schedule (ibufds_out, align_start, autoalign, training, manual_tap, rden, dataout)
      CF (ibufds_out, align_start, autoalign, training, manual_tap, rden, dataout);
endmodule: mkIserdesbvi

module mkIserdesDatadeser#(Clock clkdiv, Clock serdest, Bit#(1) align_start,
   Bit#(1) autoalign, Bit#(10) training, Bit#(10) manual_tap, Bit#(1) rden)(IserdesDatadeser);
    IserdesDatadeser serdes_v <- mkIserdesbvi(clkdiv, serdest);
    rule serdesrule;
    serdes_v.align_start(align_start);
    serdes_v.autoalign(autoalign);
    serdes_v.training(training);
    serdes_v.manual_tap(manual_tap);
    serdes_v.rden(rden);
    endrule
    method Action ibufds_out(Bit#(1) v);
        serdes_v.ibufds_out(v);
    endmethod
    method Bit#(1)                align_busy();
        return serdes_v.align_busy();
    endmethod
    method Bit#(1)                aligned();
        return serdes_v.aligned();
    endmethod
    method Bit#(1)                sampleinfirstbit();
        return serdes_v.sampleinfirstbit();
    endmethod
    method Bit#(1)                sampleinlastbit();
        return serdes_v.sampleinlastbit();
    endmethod
    method Bit#(1)                sampleinotherbit();
        return serdes_v.sampleinotherbit();
    endmethod
    method Action                 delay_wren(Bit#(1) v);
        serdes_v.delay_wren(v);
    endmethod
    method Action                 fifo_wren(Bit#(1) v);
        serdes_v.fifo_wren(v);
    endmethod
    method Action                 reset(Bit#(1) v);
        serdes_v.reset(v);
    endmethod
    method Bit#(1)                empty();
        return serdes_v.empty();
    endmethod
    method Bit#(10)               dataout();
        return serdes_v.dataout();
    endmethod
endmodule: mkIserdesDatadeser

(* always_enabled *)
interface ImageonSerdesPins;
    method Action io_vita_sync_p(Bit#(1) v);
    method Action io_vita_sync_n(Bit#(1) v);
    method Action io_vita_data_p(Bit#(4) v);
    method Action io_vita_data_n(Bit#(4) v);
    method Action io_vita_clk_p(Bit#(1) v);
    method Action io_vita_clk_n(Bit#(1) v);
endinterface

interface ImageonSerdesControl;
    method Action set_decoder_control(Bit#(32) v);
    method Action set_iserdes_control(Bit#(32) v);
    method Action set_serdes_manual_tap(Bit#(10) v);
    method Action set_serdes_training(Bit#(10) v);
    method Bit#(32) get_iserdes_control();
endinterface

interface SerdesData;
    method Wire#(Bit#(1)) reset();
    method Bit#(1) raw_empty();
    method Bit#(50) raw_data();
endinterface

interface ISerdes;
    interface ImageonSerdesControl control;
    interface ImageonSerdesPins pins;
    interface SerdesData data;
endinterface

module mkISerdes#(Clock axi_clock, Reset axi_reset)(ISerdes);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();

    Wire#(Bit#(1)) vita_clk_p <- mkDWire(0);
    Wire#(Bit#(1)) vita_clk_n <- mkDWire(0);
    Clock ibufds_clk <- mkClockIBUFDS(vita_clk_p, vita_clk_n);
    ClockGenIfc serdes_clk <- mkBUFR5(ibufds_clk);
    Clock serdes_clock = serdes_clk.gen_clk;
    Reset serdes_reset <- mkAsyncReset(2, defaultReset, serdes_clock);

    Vector#(5, Wire#(Bit#(1))) vita_data_p <- replicateM(mkDWire(0));
    Vector#(5, Wire#(Bit#(1))) vita_data_n <- replicateM(mkDWire(0));
    Reg#(Bit#(1)) decoder_enable_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(1)) serdes_auto_align_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(1)) serdes_align_start_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(1)) serdes_fifo_enable_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    ReadOnly#(Bit#(1)) serdes_fifo_enable_null <- mkNullCrossingWire(serdes_clock, serdes_fifo_enable_reg);
    Reg#(Bit#(10)) serdes_manual_tap_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(10)) serdes_training_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(1)) serdes_reset_reg <- mkSyncReg(1, axi_clock, axi_reset, defaultClock);
    ReadOnly#(Bit#(1)) serdes_reset_null <- mkNullCrossingWire(serdes_clock, serdes_reset_reg);

    Wire#(Bit#(50)) raw_data_wire <- mkDWire(0);

    Wire#(Bit#(1)) empty_wire <- mkDWire(0);
    Wire#(Bit#(1)) bittest_wire <- mkDWire(0);
    Reg#(Bit#(1)) delay_wren_r_reg <-mkReg(0);
    Reg#(Bit#(1)) delay_wren_r2_reg <- mkSyncReg(0, defaultClock, defaultReset, serdes_clock);
    Reg#(Bit#(1)) delay_wren_c_reg <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(1)) fifo_wren_r2_reg <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(1)) fifo_wren_c_reg <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);

    ClockGenIfc serdest_clk <- mkBUFIO(ibufds_clk);
    Vector#(5, ReadOnly#(Bit#(1))) ibufds_v;
    for (Integer i = 0; i < 5; i = i + 1)
        ibufds_v[i] <- mkIBUFDS(vita_data_p[i], vita_data_n[i]);
    Reg#(Bit#(1)) serdes_align_busy_temp <- mkReg(0);
    Reg#(Bit#(1)) serdes_align_busy_reg <- mkSyncReg(0, defaultClock, defaultReset, axi_clock);
    Reg#(Bit#(1)) serdes_aligned_temp <- mkReg(0);
    Reg#(Bit#(1)) serdes_aligned_reg <- mkSyncReg(0, defaultClock, defaultReset, axi_clock);
    Wire#(Bit#(1)) new_raw_empty_wire <- mkDWire(0);
    Vector#(5, IserdesDatadeser) serdes_v <- replicateM(mkIserdesDatadeser(serdes_clock, serdest_clk.gen_clk,
	  serdes_align_start_reg, serdes_auto_align_reg, serdes_training_reg,
	  serdes_manual_tap_reg, decoder_enable_reg));

    rule serdes_copybits;
        serdes_aligned_reg <= serdes_aligned_temp;
        serdes_align_busy_reg <= serdes_align_busy_temp;
    endrule

    rule sendup_imageon_clock;
       Bit#(5) alignbusyw = 0;
       Bit#(5) alignedw = 0;
       Bit#(5) firstw = 0;
       Bit#(5) lastw = 0;
       Bit#(5) otherw = 0;
       Bit#(5) emptyw = 0;
       Bit#(50) rawdataw = 0;
       for (Bit#(8) i = 0; i < 5; i = i+1) begin
	  serdes_v[i].ibufds_out(ibufds_v[i]);
	  alignbusyw[i] = serdes_v[i].align_busy();
	  alignedw[i] = serdes_v[i].aligned();
	  firstw[i] = serdes_v[i].sampleinfirstbit();
	  lastw[i] = serdes_v[i].sampleinlastbit();
	  otherw[i] = serdes_v[i].sampleinotherbit();
	  emptyw[i] = serdes_v[i].empty();
	  rawdataw[(i+1)*10-1: i*10] = serdes_v[i].dataout();
       end
       serdes_align_busy_temp <= pack(alignbusyw != 0);
       serdes_aligned_temp <= pack(alignedw == 5'b11111);
       bittest_wire <= pack(otherw == 0 && firstw != 0 && lastw != 0);
       empty_wire <= pack(emptyw != 0);
       raw_data_wire <= rawdataw;
    endrule

    rule sendup_sdes_clock;
    for (Bit#(8) i = 0; i < 5; i = i+1) begin
       serdes_v[i].reset(~serdes_reset_null);
       serdes_v[i].delay_wren(delay_wren_c_reg);
       serdes_v[i].fifo_wren(serdes_fifo_enable_null);
    end
    endrule
    
    rule serdes_reset_rule if (serdes_reset_reg == 0);
        new_raw_empty_wire <= 0;
        delay_wren_r_reg <= 0;
        delay_wren_r2_reg <= 0;
    endrule

    rule serdes_resetc_rule if (serdes_reset_null == 0);
        delay_wren_c_reg <= 0;
        fifo_wren_r2_reg <= 0;
        fifo_wren_c_reg <= 0;
    endrule

    rule serdes_calc2 if (serdes_reset_reg == 1);
        new_raw_empty_wire <= empty_wire;
        delay_wren_r_reg <= bittest_wire;
        delay_wren_r2_reg <= delay_wren_r_reg;
    endrule

    rule serdes_calc2c if (serdes_reset_null == 1);
        delay_wren_c_reg <= delay_wren_r2_reg;
        fifo_wren_r2_reg <= serdes_fifo_enable_null;
        fifo_wren_c_reg <= fifo_wren_r2_reg;
    endrule

    interface ImageonSerdesControl control;
	method Action set_serdes_manual_tap(Bit#(10) v);
	    serdes_manual_tap_reg <= v;
	endmethod
	method Action set_serdes_training(Bit#(10) v);
	    serdes_training_reg <= v;
	endmethod
	method Action set_iserdes_control(Bit#(32) v);
	    serdes_reset_reg <= ~v[0];
	    serdes_auto_align_reg <= v[1];
	    serdes_align_start_reg <= v[2];
	    serdes_fifo_enable_reg <= v[3];
	endmethod
	method Bit#(32) get_iserdes_control();
	    let v = 0;
	    v[8] = 1;
	    v[9] = serdes_align_busy_reg;
	    v[10] = serdes_aligned_reg;
	    return v;
	endmethod
	method Action set_decoder_control(Bit#(32) v);
	    decoder_enable_reg <= v[1];
	endmethod
    endinterface

    interface ImageonSerdesPins pins;
        method Action io_vita_sync_p(Bit#(1) v);
            vita_data_p[0] <= v;
        endmethod
        method Action io_vita_sync_n(Bit#(1) v);
            vita_data_n[0] <= v;
        endmethod
        method Action io_vita_data_p(Bit#(4) v);
            for (Integer i = 0; i < 4; i = i + 1)
                vita_data_p[i+1] <= v[i];
        endmethod
        method Action io_vita_data_n(Bit#(4) v);
            for (Integer i = 0; i < 4; i = i + 1)
                vita_data_n[i+1] <= v[i];
        endmethod
        method Action io_vita_clk_p(Bit#(1) v);
            vita_clk_p <= v;
        endmethod
        method Action io_vita_clk_n(Bit#(1) v);
            vita_clk_n <= v;
        endmethod
    endinterface
    interface SerdesData data;
        method Wire#(Bit#(1)) reset();
            return serdes_reset_reg;
        endmethod
        method Bit#(1) raw_empty();
            return new_raw_empty_wire;
        endmethod
        method Bit#(50) raw_data();
            return raw_data_wire;
	endmethod
    endinterface
endmodule
