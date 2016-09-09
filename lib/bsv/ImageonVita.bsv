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
`include "ConnectalProjectConfig.bsv"
import Vector::*;
import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import ConnectalClocks::*;
import ConnectalXilinxCells::*;

typedef struct {
     Bool increment;
     Bit#(1) ce;
     Bit#(1) bitslip;
} SerdesStart deriving (Bits);

interface IserdesCore;
    method Action io_vita_data_p(Bit#(1) v);
    method Action io_vita_data_n(Bit#(1) v);
    method Bit#(10) data();
endinterface: IserdesCore

module mkIserdesCore#(Clock serdes_clock, Reset serdes_reset, Clock serdest,
      Clock serdest_inverted, Bit#(1) astate_reset, SerdesStart param)(IserdesCore);
    Wire#(Bit#(1)) vita_data_p <- mkDWire(0);
    Wire#(Bit#(1)) vita_data_n <- mkDWire(0);
`ifndef SIMULATION
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    IdelayE2 delaye2 <- mkIDELAYE2(IDELAYE2_Config {
        cinvctrl_sel: "FALSE", delay_src: "IDATAIN",
        high_performance_mode: "TRUE",
        idelay_type: "VARIABLE", idelay_value: 0,
        pipe_sel: "FALSE", refclk_frequency: 200, signal_pattern: "DATA"},
        defaultClock, clocked_by serdes_clock);
    Vector#(2, IserdesE2) iserdes_v;
    iserdes_v[0] <- mkISERDESE2( ISERDESE2_Config{
        data_rate: "DDR", data_width: 10,
        dyn_clk_inv_en: "FALSE", dyn_clkdiv_inv_en: "FALSE",
        interface_type: "NETWORKING", num_ce: 2, ofb_used: "FALSE",
        init_q1: 0, init_q2: 0, init_q3: 0, init_q4: 0,
        srval_q1: 0, srval_q2: 0, srval_q3: 0, srval_q4: 0,
        serdes_mode: "MASTER", iobdelay: "IFD"},
        serdest, serdest_inverted, clocked_by serdes_clock, reset_by serdes_reset);
    iserdes_v[1] <- mkISERDESE2( ISERDESE2_Config{
        data_rate: "DDR", data_width: 10,
        dyn_clk_inv_en: "FALSE", dyn_clkdiv_inv_en: "FALSE",
        interface_type: "NETWORKING", num_ce: 2, ofb_used: "FALSE",
        init_q1: 0, init_q2: 0, init_q3: 0, init_q4: 0,
        srval_q1: 0, srval_q2: 0, srval_q3: 0, srval_q4: 0,
        serdes_mode: "SLAVE", iobdelay: "NONE"},
        serdest, serdest_inverted, clocked_by serdes_clock, reset_by serdes_reset);
    ReadOnly#(Bit#(1))ibufds_v <- mkIBUFDS(vita_data_p, vita_data_n);

    (* no_implicit_conditions *)
    rule setruledata;
        delaye2.idatain(ibufds_v);
    endrule
    (* no_implicit_conditions *)
    rule setrule;
        delaye2.reset(astate_reset);
        delaye2.cinvctrl(0);
        delaye2.cntvaluein(0);
        delaye2.ld(0);
        delaye2.ldpipeen(0);
        delaye2.datain(0);
        delaye2.inc(param.increment);
        delaye2.ce(param.ce);
        for (Integer i = 0; i < 2; i = i + 1)
            begin
            iserdes_v[i].d(0);
            iserdes_v[i].bitslip(param.bitslip);
            iserdes_v[i].ce1(1);
            iserdes_v[i].ce2(1);
            iserdes_v[i].ofb(0);
            iserdes_v[i].dynclkdivsel(0);
            iserdes_v[i].dynclksel(0);
            iserdes_v[i].oclk(0);
            iserdes_v[i].oclkb(0);
            iserdes_v[i].reset(astate_reset);
            end
        iserdes_v[0].ddly(delaye2.dataout());
        iserdes_v[0].shiftin1(0);
        iserdes_v[0].shiftin2(0);
        iserdes_v[1].ddly(0);
        iserdes_v[1].shiftin1(iserdes_v[0].shiftout1());
        iserdes_v[1].shiftin2(iserdes_v[0].shiftout2());
    endrule
    method Bit#(10) data();
        return {iserdes_v[1].q4(), iserdes_v[1].q3(), iserdes_v[0].q8(),
           iserdes_v[0].q7(), iserdes_v[0].q6(), iserdes_v[0].q5(),
           iserdes_v[0].q4(), iserdes_v[0].q3(), iserdes_v[0].q2(), iserdes_v[0].q1()};
`else
    method Bit#(10) data();
        return 0;
`endif
    endmethod
    method Action io_vita_data_p(Bit#(1) v);
        vita_data_p <= v;
    endmethod
    method Action io_vita_data_n(Bit#(1) v);
        vita_data_n <= v;
    endmethod
endmodule

interface SerdesClock;
    interface Clock serdes_clkif;
    interface Reset serdes_resetif;
    interface Clock serdest_clkif;
    method Action io_vita_clk_p(Bit#(1) v);
    method Action io_vita_clk_n(Bit#(1) v);
endinterface
(* synthesize *)
module mkSerdesClock(SerdesClock);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
`ifdef SIMULATION
    Wire#(Bit#(1)) vita_clk_p <- mkDWire(0);
    Wire#(Bit#(1)) vita_clk_n <- mkDWire(0);
    interface Clock serdes_clkif = defaultClock;
    interface Reset serdes_resetif = defaultReset;
    interface Clock serdest_clkif = defaultClock;
    method Action io_vita_clk_p(Bit#(1) v);
    endmethod
    method Action io_vita_clk_n(Bit#(1) v);
    endmethod
`else
    B2C1 vita_clk_p <- mkB2C1();
    B2C1 vita_clk_n <- mkB2C1();
    Clock ibufds_clk <- mkClockIBUFDS(
`ifdef ClockDefaultParam
        defaultValue,
`endif
        vita_clk_p.c, vita_clk_n.c);
    ClockGenIfc serdes_clk <- mkBUFR5(ibufds_clk);
    ClockGenIfc serdest_clk <- mkBUFIO(ibufds_clk);
    Reset serdes_reset <- mkAsyncReset(2, defaultReset, serdes_clk.gen_clk);
    interface Clock serdes_clkif = serdes_clk.gen_clk;
    interface Reset serdes_resetif = serdes_reset;
    interface Clock serdest_clkif = serdest_clk.gen_clk;
    method Action io_vita_clk_p(Bit#(1) v);
        vita_clk_p.inputclock(v);
    endmethod
    method Action io_vita_clk_n(Bit#(1) v);
        vita_clk_n.inputclock(v);
    endmethod
`endif
endmodule

interface ImageClocks;
   interface Clock imageon;
   interface Clock hdmi;
endinterface
(* synthesize *)
module mkImageClocks#(Clock fmc_imageon_clk1)(ImageClocks);
`ifndef SIMULATION
   ClockGenerator7AdvParams clockParams = defaultValue;
   clockParams.bandwidth          = "OPTIMIZED";
   clockParams.compensation       = "ZHOLD";
   clockParams.clkfbout_mult_f    = 8.000;
   clockParams.clkfbout_phase     = 0.0;
   clockParams.clkin1_period      = 6.734007; // 148.5 MHz
   clockParams.clkin2_period      = 6.734007;
   clockParams.clkout0_divide_f   = 8.000;    // 148.5 MHz
   clockParams.clkout0_duty_cycle = 0.5;
   clockParams.clkout0_phase      = 0.0000;
   clockParams.clkout1_divide     = 32;       // 37.125 MHz
   clockParams.clkout1_duty_cycle = 0.5;
   clockParams.clkout1_phase      = 0.0000;
   clockParams.divclk_divide      = 1;
   clockParams.ref_jitter1        = 0.010;
   clockParams.ref_jitter2        = 0.010;
   XClockGenerator7 clockGen <- mkClockGenerator7Adv(clockParams, clocked_by fmc_imageon_clk1);
   C2B c2b_fb <- mkC2B(clockGen.clkfbout, clocked_by clockGen.clkfbout);
   rule txoutrule5;
      clockGen.clkfbin(c2b_fb.o());
   endrule
   Clock hdmi_clock <- mkClockBUFG(clocked_by clockGen.clkout0);    // 148.5   MHz
   Clock imageon_clock <- mkClockBUFG(clocked_by clockGen.clkout1); //  37.125 MHz
`else
   Clock defaultClock <- exposeCurrentClock();
   Clock hdmi_clock = defaultClock;
   Clock imageon_clock = defaultClock;
`endif
   interface hdmi = hdmi_clock;
   interface imageon = imageon_clock;
endmodule
