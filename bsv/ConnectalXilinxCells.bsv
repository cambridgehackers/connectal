
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

import Clocks       :: *;
import DefaultValue :: *;
import XilinxCells  :: *;
import Vector       :: *;

`include "ConnectalProjectConfig.bsv"

import "BVI" IBUFDS =
module mkIBUFDS#(Wire#(one_bit) i, Wire#(one_bit) ib)(ReadOnly#(one_bit)) provisos(Bits#(one_bit,1));
   default_clock clk();
   default_reset rstn();

   parameter CAPACITANCE = "DONT_CARE";
   parameter DIFF_TERM = 1;
   parameter IBUF_DELAY_VALUE = 0;
   parameter IFD_DELAY_VALUE = "AUTO";
   parameter IOSTANDARD = "DEFAULT";

   port I = i;
   port IB = ib;
   method O    _read;

   path(I, O);
   path(IB, O);

   schedule _read  CF _read;

endmodule: mkIBUFDS

import "BVI" IBUFDS =
module vMkConnectalClockIBUFDS#(Wire#(one_bit) i, Wire#(one_bit) ib)(ClockGenIfc) provisos(Bits#(one_bit,1));
   default_clock clk();
   default_reset rstn();
   parameter CAPACITANCE = "DONT_CARE";
   parameter DIFF_TERM = 1;
   parameter IBUF_DELAY_VALUE = 0;
   parameter IFD_DELAY_VALUE = "AUTO";
   parameter IOSTANDARD = "DEFAULT";
   port I = i;
   port IB = ib;
   //method O    _read;
   output_clock gen_clk(O);
   path(I, O);
   path(IB, O);
   //schedule _read  CF _read;
endmodule: vMkConnectalClockIBUFDS

module mkConnectalClockIBUFDS#(Wire#(one_bit) i, Wire#(one_bit) ib)(Clock) provisos(Bits#(one_bit,1));
   let _m <- vMkConnectalClockIBUFDS(i, ib);
   return _m.gen_clk;
endmodule: mkConnectalClockIBUFDS

interface DiffPair;
   method Bit#(1) p;
   method Bit#(1) n;
endinterface

import "BVI" OBUFDS =
module vMkOBUFDS#(Bit#(1) i)(DiffPair);
   default_clock clk();
   default_reset reset();

   port I = i;

   method O p;
   method OB n;

   path(I, O);
   path(I, OB);

   schedule (p, n) CF (p, n);

endmodule: vMkOBUFDS

module mkOBUFDS#(Bit#(1) i)(DiffPair);
   let _m <- vMkOBUFDS(i);
   return _m;
endmodule: mkOBUFDS

import "BVI" IBUFDS_GTE2 =
module vMkConnectalClockIBUFDS_GTE2#(Bool enable, Wire#(one_bit) i, Wire#(one_bit) ib)(ClockGenIfc) provisos(Bits#(one_bit,1));
   default_clock clk();
   default_reset rstn();
   port CEB = pack(!enable);
   port I = i;
   port IB = ib;
   //method O    _read;
   output_clock gen_clk(O);
   //output_clock gen_clk_div2(ODIV2);
   path(I, O);
   path(IB, O);
   //path(I, ODIV2);
   //path(IB, ODIV2);
endmodule: vMkConnectalClockIBUFDS_GTE2

module mkConnectalClockIBUFDS_GTE2#(Bool enable, Wire#(one_bit) i, Wire#(one_bit) ib)(Clock) provisos(Bits#(one_bit,1));
   let _m <- vMkConnectalClockIBUFDS_GTE2(enable, i, ib);
   return _m.gen_clk;
endmodule: mkConnectalClockIBUFDS_GTE2

import "BVI" OBUFT =
module mkOBUFT#(ReadOnly#(one_bit) i, ReadOnly#(oneb_bit) t)(ReadOnly#(onec_bit)) provisos(Bits#(one_bit,1), Bits#(oneb_bit,1), Bits#(onec_bit,1));
   default_clock clk();
   default_reset rstn();

   port I = i;
   port T = t;
   method O    _read;

   path(I, O);
   path(T, O);

   schedule _read  CF _read;

endmodule: mkOBUFT

typedef struct {
   String cinvctrl_sel;           // "TRUE" to enable dynamic clock inversion, "FALSE" otherwise
   String delay_src;              // "IDATAIN" or "DATAIN"
   String high_performance_mode;  // "TRUE" to reduce jitter, "FALSE" to reduce power
   String idelay_type;            // "FIXED", "VAR_LOAD", or "VAR_LOAD_PIPE"
   Integer idelay_value;          // 0-31 input delay tap setting
   String pipe_sel;               // "TRUE" to select pipelined mode
   Integer refclk_frequency;      // idelayctrl clock input freq in MHz
   String signal_pattern;         // "DATA" or "CLOCK" input signal
}  IDELAYE2_Config;

instance DefaultValue#(IDELAYE2_Config);
   defaultValue =
   IDELAYE2_Config {
      cinvctrl_sel: "FALSE",
      delay_src: "IDATAIN",
      high_performance_mode: "FALSE",
      idelay_type: "FIXED",
      idelay_value: 0,
      pipe_sel: "FALSE",
      refclk_frequency: 200,
      signal_pattern: "DATA"
      };
endinstance

(* always_ready, always_enabled *)
interface IdelayE2;
   method Bit#(5) cntvalueout();
   method Action cinvctrl(Bit#(1) v);
   method Action cntvaluein(Bit#(5) v);
   method Action ld(Bit#(1) v);
   method Action ldpipeen(Bit#(1) v);
   method Action inc(Bool inc);
   method Action ce(Bit#(1) v);
   method Action datain(Bit#(1) v);
   method Action idatain(Bit#(1) v);
   method Action reset(Bit#(1) v);
   method Bit#(1) dataout();
endinterface

import "BVI" IDELAYE2 =
module mkIDELAYE2#(IDELAYE2_Config cfg, Clock serdes_clock)(IdelayE2);
   default_clock clk(C);
   //default_reset rst(REGRST);
   no_reset;
   input_clock serdes ()= serdes_clock;

   parameter CINVCTRL_SEL = cfg.cinvctrl_sel;
   parameter DELAY_SRC = cfg.delay_src;
   parameter HIGH_PERFORMANCE_MODE = cfg.high_performance_mode;
   parameter IDELAY_TYPE = cfg.idelay_type;
   parameter IDELAY_VALUE = cfg.idelay_value;
   parameter PIPE_SEL = cfg.pipe_sel;
   parameter REFCLK_FREQUENCY = cfg.refclk_frequency;
   parameter SIGNAL_PATTERN = cfg.signal_pattern;

   method CNTVALUEOUT cntvalueout();
   method cinvctrl(CINVCTRL) enable((*inhigh*) en0);
   method cntvaluein(CNTVALUEIN) enable((*inhigh*) en1);

   method ld(LD) enable((*inhigh*) en20);

   // is LDPIPEEN the enable for DATAIN?
   method ldpipeen(LDPIPEEN) enable((*inhigh*) en21);

   method DATAOUT dataout();
   method inc(INC) enable((*inhigh*) en5);
   method ce(CE) enable((*inhigh*) en4);
   method reset(REGRST) enable((*inhigh*) en7);
   method datain(DATAIN) enable((*inhigh*) en2);
   method idatain(IDATAIN) enable((*inhigh*) en3) clocked_by(serdes);

   schedule (datain, idatain, inc, ce) CF (datain, idatain, inc, ce);
   schedule (reset, cntvalueout, dataout, ld, datain, ldpipeen, inc, cinvctrl, cntvaluein, ce, idatain) CF (reset, cntvalueout, dataout, ld, datain, ldpipeen, inc, cinvctrl, cntvaluein, ce, idatain);
endmodule

////////////////////////////////////////////////////////////
typedef struct {
   String data_rate;
   Integer data_width;
   String dyn_clk_inv_en;
   String dyn_clkdiv_inv_en;
   Integer init_q1;
   Integer init_q2;
   Integer init_q3;
   Integer init_q4;
   String interface_type;
   String iobdelay;
   Integer num_ce;
   String ofb_used;
   String serdes_mode;
   Integer srval_q1;
   Integer srval_q2;
   Integer srval_q3;
   Integer srval_q4;
}  ISERDESE2_Config;

instance DefaultValue#(ISERDESE2_Config);
   defaultValue =
   ISERDESE2_Config {
      data_rate: "DDR",
      data_width: 8,
      dyn_clk_inv_en: "FALSE",
      dyn_clkdiv_inv_en: "FALSE",
      init_q1: 0,
      init_q2: 0,
      init_q3: 0,
      init_q4: 0,
      interface_type: "NETWORKING",
      iobdelay: "IBUF",
      num_ce: 1,
      ofb_used: "FALSE",
      serdes_mode: "MASTER",
      srval_q1: 0,
      srval_q2: 0,
      srval_q3: 0,
      srval_q4: 0
      };
endinstance

(* always_ready, always_enabled *)
interface IserdesE2;
   (* prefix = "" *)
   method Action d(Bit#(1) d);
   method Bit#(1) o();
   method Action bitslip(Bit#(1) bitslip);
   method Action ce1(Bit#(1) ce1);
   method Action ce2(Bit#(1) ce2);
   method Action ddly(Bit#(1) ddly);
   method Action shiftin1(Bit#(1) shiftin1);
   method Action shiftin2(Bit#(1) shiftin2);
   method Bit#(1) q1();
   method Bit#(1) q2();
   method Bit#(1) q3();
   method Bit#(1) q4();
   method Bit#(1) q5();
   method Bit#(1) q6();
   method Bit#(1) q7();
   method Bit#(1) q8();
   method Bit#(1) shiftout1();
   method Bit#(1) shiftout2();
   method Action ofb(Bit#(1) ofb);
   method Action dynclkdivsel(Bit#(1) dynclkdivsel);
   method Action dynclksel(Bit#(1) dynclksel);
   method Action oclk(Bit#(1) v);
   method Action oclkb(Bit#(1) v);
   method Action reset(Bit#(1) d);
endinterface

import "BVI" ISERDESE2 =
module mkISERDESE2#(ISERDESE2_Config cfg, Clock clk, Clock clkb)(IserdesE2);
   input_clock clk(CLK) = clk;
   input_clock clkb(CLKB) = clkb;
   default_clock clkdiv(CLKDIV);
   no_reset;

   parameter DATA_RATE = cfg.data_rate;
   parameter DATA_WIDTH = cfg.data_width;
   parameter DYN_CLK_INV_EN = cfg.dyn_clk_inv_en;
   parameter DYN_CLKDIV_INV_EN = cfg.dyn_clkdiv_inv_en;
   parameter INIT_Q1 = cfg.init_q1;
   parameter INIT_Q2 = cfg.init_q2;
   parameter INIT_Q3 = cfg.init_q3;
   parameter INIT_Q4 = cfg.init_q4;
   parameter INTERFACE_TYPE = cfg.interface_type;
   parameter IOBDELAY = cfg.iobdelay;
   parameter NUM_CE = cfg.num_ce;
   parameter OFB_USED = cfg.ofb_used;
   parameter SERDES_MODE = cfg.serdes_mode;
   parameter SRVAL_Q1 = cfg.srval_q1;
   parameter SRVAL_Q2 = cfg.srval_q2;
   parameter SRVAL_Q3 = cfg.srval_q3;
   parameter SRVAL_Q4 = cfg.srval_q4;

   port CLKDIVP = 0; // unused
   path (D, O);

   method d(D) enable ((*inhigh*) en0);
   method O o();
   method bitslip(BITSLIP) enable ((*inhigh*)enbitslip);
   method ce1(CE1) enable ((*inhigh*) en1);
   method ce2(CE2) enable ((*inhigh*) en2);
   method ddly(DDLY) enable ((*inhigh*) en3);
   method shiftin1(SHIFTIN1) enable ((*inhigh*) en4);
   method shiftin2(SHIFTIN2) enable ((*inhigh*) en5);
   method Q1 q1();
   method Q2 q2();
   method Q3 q3();
   method Q4 q4();
   method Q5 q5();
   method Q6 q6();
   method Q7 q7();
   method Q8 q8();
   method SHIFTOUT1 shiftout1();
   method SHIFTOUT2 shiftout2();
   method ofb(OFB) enable ((*inhigh*) en6);
   method oclk(OCLK) enable ((*inhigh*) en10);
   method oclkb(OCLKB) enable ((*inhigh*) en11);
   method dynclkdivsel(DYNCLKDIVSEL) enable ((*inhigh*) en7);
   method dynclksel(DYNCLKSEL) enable ((*inhigh*) en8);
   method reset(RST) enable ((*inhigh*) en14);

   schedule (reset, o, q1, q2, q3, q4, q5, q6, q7, q8, shiftout1, shiftout2, d, bitslip, ce1, ce2, ddly, shiftin1, shiftin2, ofb, dynclkdivsel, dynclksel, oclk, oclkb)
         CF (reset, o, q1, q2, q3, q4, q5, q6, q7, q8, shiftout1, shiftout2, d, bitslip, ce1, ce2, ddly, shiftin1, shiftin2, ofb, dynclkdivsel, dynclksel, oclk, oclkb);
endmodule

import "BVI" BUFR =
module mkBUFR5#(Clock clk)(ClockGenIfc);
   default_clock clkunused();
   default_reset rstn();
  
   parameter BUFR_DIVIDE = "5";
  
   input_clock clk(I) = clk;
   output_clock gen_clk(O);
   port   CE = True;
   port   CLR = False;
   path(I, O);
endmodule

import "BVI" BUFIO =
module mkBUFIO#(Clock clk)(ClockGenIfc);
   default_clock clkunused();
   default_reset rstn();
   input_clock clk(I) = clk;
   output_clock gen_clk(O);
   path(I, O);
endmodule

(* always_ready, always_enabled *)
interface ConnectalODDR#(type a);
   method    a            q();
   method    Action       s(Bool i);
   method    Action       ce(Bool i);
   method    Action       d1(a i);
   method    Action       d2(a i);
endinterface: ConnectalODDR

import "BVI" ODDR =
module mkConnectalODDR#(ODDRParams#(a) params)(ConnectalODDR#(a))
   provisos(Bits#(a, 1), DefaultValue#(a));

   if (params.srtype != "SYNC" &&
       params.srtype != "ASYNC")
      error("There are only two modes of reset of the ODDR cell SYNC and ASYNC.  Please specify one of those.");

   if (params.ddr_clk_edge != "OPPOSITE_EDGE" &&
       params.ddr_clk_edge != "SAME_EDGE")
      error("There are only two modes of operation of the ODDR cell OPPOSITE_EDGE and SAME_EDGE.  Please specify one of those.");

   no_reset;
   default_clock clk(C);
   //default_reset rst(R);
   port R = 0;

   parameter DDR_CLK_EDGE = params.ddr_clk_edge;
   parameter INIT         = pack(params.init);
   parameter SRTYPE       = params.srtype;

   method Q   q reset_by(no_reset);
   method     s(S)     enable((*inhigh*)en0) reset_by(no_reset);
   method     ce(CE)   enable((*inhigh*)en1) reset_by(no_reset);
   method     d1(D1)   enable((*inhigh*)en2) reset_by(no_reset);
   method     d2(D2)   enable((*inhigh*)en3) reset_by(no_reset);

   schedule (q)      SB (d1, d2);
   schedule (d1)     CF (d2);
   schedule (d1)     C  (d1);
   schedule (d2)     C  (d2);
   schedule (q)      CF (q);
   schedule (ce, s)  CF (ce, s);
   schedule (ce, s)  SB (d1, d2, q);
endmodule: mkConnectalODDR

////////////////////////////////////////////////////////////////////////////////
/// ClockGenerator Xilinx 7 Adv
////////////////////////////////////////////////////////////////////////////////
typedef struct {
   String      bandwidth;
   String      compensation;
   Bool        clkin_buffer;
   Real        clkin1_period;
   Real        clkin2_period;
   Integer     reset_stages;
   Real        clkfbout_mult_f;
   Real        clkfbout_phase;
   Integer     divclk_divide;
   Bool        clkout0_buffer;
   Bool        clkout0n_buffer;
   Real        clkout0_divide_f;
   Real        clkout0_duty_cycle;
   Real        clkout0_phase;
   Bool        clkout1_buffer;
   Bool        clkout1n_buffer;
   Integer     clkout1_divide;
   Real        clkout1_duty_cycle;
   Real        clkout1_phase;
   Bool        clkout2_buffer;
   Bool        clkout2n_buffer;
   Integer     clkout2_divide;
   Real        clkout2_duty_cycle;
   Real        clkout2_phase;
   Bool        clkout3_buffer;
   Bool        clkout3n_buffer;
   Integer     clkout3_divide;
   Real        clkout3_duty_cycle;
   Real        clkout3_phase;
   Bool        clkout4_buffer;
   Integer     clkout4_divide;
   Real        clkout4_duty_cycle;
   Real        clkout4_phase;
   Bool        clkout5_buffer;
   Integer     clkout5_divide;
   Real        clkout5_duty_cycle;
   Real        clkout5_phase;
   Bool        clkout6_buffer;
   Integer     clkout6_divide;
   Real        clkout6_duty_cycle;
   Real        clkout6_phase;
   Real        ref_jitter1;
   Real        ref_jitter2;
   Bool        use_same_family;
} ClockGenerator7AdvParams deriving (Bits, Eq);

instance DefaultValue#(ClockGenerator7AdvParams);
   defaultValue = ClockGenerator7AdvParams {
      bandwidth:          "OPTIMIZED",
      compensation:       "ZHOLD",
      clkin_buffer:       True,
      clkin1_period:      5.000,
      clkin2_period:      0.000,
      reset_stages:       3,
      clkfbout_mult_f:    1.000,
      clkfbout_phase:     0.000,
      divclk_divide:      1,
      clkout0_buffer:     True,
      clkout0n_buffer:    True,
      clkout0_divide_f:   1.000,
      clkout0_duty_cycle: 0.500,
      clkout0_phase:      0.000,
      clkout1_buffer:     True,
      clkout1n_buffer:    True,
      clkout1_divide:     1,
      clkout1_duty_cycle: 0.500,
      clkout1_phase:      0.000,
      clkout2_buffer:     True,
      clkout2n_buffer:    True,
      clkout2_divide:     1,
      clkout2_duty_cycle: 0.500,
      clkout2_phase:      0.000,
      clkout3_buffer:     True,
      clkout3n_buffer:    True,
      clkout3_divide:     1,
      clkout3_duty_cycle: 0.500,
      clkout3_phase:      0.000,
      clkout4_buffer:     True,
      clkout4_divide:     1,
      clkout4_duty_cycle: 0.500,
      clkout4_phase:      0.000,
      clkout5_buffer:     True,
      clkout5_divide:     1,
      clkout5_duty_cycle: 0.500,
      clkout5_phase:      0.000,
      clkout6_buffer:     True,
      clkout6_divide:     1,
      clkout6_duty_cycle: 0.500,
      clkout6_phase:      0.000,
      ref_jitter1:        0.010,
      ref_jitter2:        0.010,
      use_same_family:    False
      };
endinstance

interface XVMMCME2;
   interface Clock     clkout0;
   interface Clock     clkout0_n;
   interface Clock     clkout1;
   interface Clock     clkout1_n;
   interface Clock     clkout2;
   interface Clock     clkout2_n;
   interface Clock     clkout3;
   interface Clock     clkout3_n;
   interface Clock     clkout4;
   interface Clock     clkout5;
   interface Clock     clkout6;
   interface Clock     clkfbout;
   interface Clock     clkfbout_n;
   (* always_ready, always_enabled *)
   method    Bool      locked;
   (* always_ready, always_enabled *)
   method    Action    clkfbin(Bit#(1) clk);
endinterface

import "BVI" MMCME2_ADV =
module vMkXMMCME2_ADV#(MMCMParams params)(XVMMCME2);
   Reset reset <- invertCurrentReset;
   
   default_clock clk1(CLKIN1);
   default_reset rst(RST) = reset;
   
   parameter BANDWIDTH            = params.bandwidth;
   parameter CLKFBOUT_USE_FINE_PS = params.clkfbout_use_fine_ps;
   parameter CLKOUT0_USE_FINE_PS  = params.clkout0_use_fine_ps;
   parameter CLKOUT1_USE_FINE_PS  = params.clkout1_use_fine_ps;
   parameter CLKOUT2_USE_FINE_PS  = params.clkout2_use_fine_ps;
   parameter CLKOUT3_USE_FINE_PS  = params.clkout3_use_fine_ps;
   parameter CLKOUT4_CASCADE      = params.clkout4_cascade;
   parameter CLKOUT4_USE_FINE_PS  = params.clkout4_use_fine_ps;
   parameter CLKOUT5_USE_FINE_PS  = params.clkout5_use_fine_ps;
   parameter CLKOUT6_USE_FINE_PS  = params.clkout6_use_fine_ps;
   parameter COMPENSATION         = params.compensation;
   parameter STARTUP_WAIT         = params.startup_wait;
   parameter CLKFBOUT_MULT_F      = params.clkfbout_mult_f;
   parameter CLKFBOUT_PHASE       = params.clkfbout_phase;
   parameter CLKIN1_PERIOD        = params.clkin1_period;
   parameter CLKIN2_PERIOD        = params.clkin2_period;
   parameter DIVCLK_DIVIDE        = params.divclk_divide;
   parameter CLKOUT0_DIVIDE_F     = params.clkout0_divide_f;
   parameter CLKOUT0_DUTY_CYCLE   = params.clkout0_duty_cycle;
   parameter CLKOUT0_PHASE        = params.clkout0_phase;
   parameter CLKOUT1_DIVIDE       = params.clkout1_divide;
   parameter CLKOUT1_DUTY_CYCLE   = params.clkout1_duty_cycle;
   parameter CLKOUT1_PHASE        = params.clkout1_phase;
   parameter CLKOUT2_DIVIDE       = params.clkout2_divide;
   parameter CLKOUT2_DUTY_CYCLE   = params.clkout2_duty_cycle;
   parameter CLKOUT2_PHASE        = params.clkout2_phase;
   parameter CLKOUT3_DIVIDE       = params.clkout3_divide;
   parameter CLKOUT3_DUTY_CYCLE   = params.clkout3_duty_cycle;
   parameter CLKOUT3_PHASE        = params.clkout3_phase;
   parameter CLKOUT4_DIVIDE       = params.clkout4_divide;
   parameter CLKOUT4_DUTY_CYCLE   = params.clkout4_duty_cycle;
   parameter CLKOUT4_PHASE        = params.clkout4_phase;
   parameter CLKOUT5_DIVIDE       = params.clkout5_divide;
   parameter CLKOUT5_DUTY_CYCLE   = params.clkout5_duty_cycle;
   parameter CLKOUT5_PHASE        = params.clkout5_phase;
   parameter CLKOUT6_DIVIDE       = params.clkout6_divide;
   parameter CLKOUT6_DUTY_CYCLE   = params.clkout6_duty_cycle;
   parameter CLKOUT6_PHASE        = params.clkout6_phase;
   parameter REF_JITTER1          = params.ref_jitter1;
   parameter REF_JITTER2          = params.ref_jitter2;
   
   port CLKIN2       = Bit#(1)'(0);
   port CLKINSEL     = Bit#(1)'(1);
   port DADDR        = Bit#(7)'(0);
   port DCLK         = Bit#(1)'(0);
   port DEN          = Bit#(1)'(0);
   port DI           = Bit#(16)'(0);
   port DWE          = Bit#(1)'(0);
   port PSCLK        = Bit#(1)'(0);
   port PSEN         = Bit#(1)'(0);
   port PSINCDEC     = Bit#(1)'(0);
   port PWRDWN       = Bit#(1)'(0);
   
   output_clock clkfbout(CLKFBOUT);
   output_clock clkfbout_n(CLKFBOUTB);
   output_clock clkout0(CLKOUT0);
   output_clock clkout0_n(CLKOUT0B);
   output_clock clkout1(CLKOUT1);
   output_clock clkout1_n(CLKOUT1B);
   output_clock clkout2(CLKOUT2);
   output_clock clkout2_n(CLKOUT2B);
   output_clock clkout3(CLKOUT3);
   output_clock clkout3_n(CLKOUT3B);
   output_clock clkout4(CLKOUT4);
   output_clock clkout5(CLKOUT5);
   output_clock clkout6(CLKOUT6);
   
   method LOCKED     locked()     clocked_by(no_clock) reset_by(no_reset);
   method            clkfbin(CLKFBIN) enable((*inhigh*)en1) clocked_by(clkfbout) reset_by(no_reset);
      
   schedule clkfbin C clkfbin;
   schedule locked CF (clkfbin, locked);
endmodule

interface XClockGenerator7;
   interface Clock        clkout0;
   interface Clock        clkout0_n;
   interface Clock        clkout1;
   interface Clock        clkout1_n;
   interface Clock        clkout2;
   interface Clock        clkout2_n;
   interface Clock        clkout3;
   interface Clock        clkout3_n;
   interface Clock        clkout4;
   interface Clock        clkout5;
   interface Clock        clkout6;
   interface Clock     clkfbout;
   (* always_ready *)
   method    Bool         locked;
   (* always_ready, always_enabled *)
   method    Action    clkfbin(Bit#(1) clk);
endinterface

module mkClockGenerator7Adv#(ClockGenerator7AdvParams params)(XClockGenerator7);

   ////////////////////////////////////////////////////////////////////////////////
   /// Clocks & Resets
   ////////////////////////////////////////////////////////////////////////////////
   Clock                                     clk                 <- exposeCurrentClock;
   Clock                                     clk_buffered         = ?;

   if (params.clkin_buffer) begin
      Clock inbuffer <- mkClockIBUFG
`ifdef ClockDefaultParam
          (defaultValue)
`endif
          ;
      clk_buffered = inbuffer;
   end
   else begin
      clk_buffered = clk;
   end

   //Reset                                     rst_n               <- mkAsyncResetFromCR(params.reset_stages, clk_buffered);
   //Reset                                     rst                 <- mkResetInverter(rst_n);

   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   MMCMParams                                clkgen_params        = defaultValue;
   clkgen_params.bandwidth          = params.bandwidth;
   clkgen_params.compensation       = params.compensation;
   clkgen_params.clkin1_period      = params.clkin1_period;
   clkgen_params.clkin2_period      = params.clkin2_period;
   clkgen_params.clkfbout_mult_f    = params.clkfbout_mult_f;
   clkgen_params.clkfbout_phase     = params.clkfbout_phase;
   clkgen_params.divclk_divide      = params.divclk_divide;
   clkgen_params.clkout0_divide_f   = params.clkout0_divide_f;
   clkgen_params.clkout0_duty_cycle = params.clkout0_duty_cycle;
   clkgen_params.clkout0_phase      = params.clkout0_phase;
   clkgen_params.clkout1_divide     = params.clkout1_divide;
   clkgen_params.clkout1_duty_cycle = params.clkout1_duty_cycle;
   clkgen_params.clkout1_phase      = params.clkout1_phase;
   clkgen_params.clkout2_divide     = params.clkout2_divide;
   clkgen_params.clkout2_duty_cycle = params.clkout2_duty_cycle;
   clkgen_params.clkout2_phase      = params.clkout2_phase;
   clkgen_params.clkout3_divide     = params.clkout3_divide;
   clkgen_params.clkout3_duty_cycle = params.clkout3_duty_cycle;
   clkgen_params.clkout3_phase      = params.clkout3_phase;
   clkgen_params.clkout4_divide     = params.clkout4_divide;
   clkgen_params.clkout4_duty_cycle = params.clkout4_duty_cycle;
   clkgen_params.clkout4_phase      = params.clkout4_phase;
   clkgen_params.clkout5_divide     = params.clkout5_divide;
   clkgen_params.clkout5_duty_cycle = params.clkout5_duty_cycle;
   clkgen_params.clkout5_phase      = params.clkout5_phase;
   clkgen_params.clkout6_divide     = params.clkout6_divide;
   clkgen_params.clkout6_duty_cycle = params.clkout6_duty_cycle;
   clkgen_params.clkout6_phase      = params.clkout6_phase;
   clkgen_params.ref_jitter1        = params.ref_jitter1;
   clkgen_params.ref_jitter2        = params.ref_jitter2;
   clkgen_params.use_same_family    = params.use_same_family;

   XVMMCME2 pll <- vMkXMMCME2_ADV(clkgen_params);

   //(* fire_when_enabled, no_implicit_conditions *)
   //rule connect_feedback;
      //pll.clkfbin( pll.clkfbout);
   //endrule

   Clock                                     clkout0_buf          = ?;
   Clock                                     clkout0n_buf         = ?;
   Clock                                     clkout1_buf          = ?;
   Clock                                     clkout1n_buf         = ?;
   Clock                                     clkout2_buf          = ?;
   Clock                                     clkout2n_buf         = ?;
   Clock                                     clkout3_buf          = ?;
   Clock                                     clkout3n_buf         = ?;
   Clock                                     clkout4_buf          = ?;
   Clock                                     clkout5_buf          = ?;
   Clock                                     clkout6_buf          = ?;

   if (params.clkout0_buffer) begin
      Clock clkout0buffer <- mkClockBUFG(clocked_by pll.clkout0);
      clkout0_buf = clkout0buffer;
   end
   else begin
      clkout0_buf = pll.clkout0;
   end

   if (params.clkout0n_buffer) begin
      Clock clkout0nbuffer <- mkClockBUFG(clocked_by pll.clkout0_n);
      clkout0n_buf = clkout0nbuffer;
   end
   else begin
      clkout0n_buf = pll.clkout0_n;
   end

   if (params.clkout1_buffer) begin
      Clock clkout1buffer <- mkClockBUFG(clocked_by pll.clkout1);
      clkout1_buf = clkout1buffer;
   end
   else begin
      clkout1_buf = pll.clkout1;
   end

   if (params.clkout1n_buffer) begin
      Clock clkout1nbuffer <- mkClockBUFG(clocked_by pll.clkout1_n);
      clkout1n_buf = clkout1nbuffer;
   end
   else begin
      clkout1n_buf = pll.clkout1_n;
   end

   if (params.clkout2_buffer) begin
      Clock clkout2buffer <- mkClockBUFG(clocked_by pll.clkout2);
      clkout2_buf = clkout2buffer;
   end
   else begin
      clkout2_buf = pll.clkout2;
   end

   if (params.clkout2n_buffer) begin
      Clock clkout2nbuffer <- mkClockBUFG(clocked_by pll.clkout2_n);
      clkout2n_buf = clkout2nbuffer;
   end
   else begin
      clkout2n_buf = pll.clkout2_n;
   end

   if (params.clkout3_buffer) begin
      Clock clkout3buffer <- mkClockBUFG(clocked_by pll.clkout3);
      clkout3_buf = clkout3buffer;
   end
   else begin
      clkout3_buf = pll.clkout3;
   end

   if (params.clkout3n_buffer) begin
      Clock clkout3nbuffer <- mkClockBUFG(clocked_by pll.clkout3_n);
      clkout3n_buf = clkout3nbuffer;
   end
   else begin
      clkout3n_buf = pll.clkout3_n;
   end

   if (params.clkout4_buffer) begin
      Clock clkout4buffer <- mkClockBUFG(clocked_by pll.clkout4);
      clkout4_buf = clkout4buffer;
   end
   else begin
      clkout4_buf = pll.clkout4;
   end

   if (params.clkout5_buffer) begin
      Clock clkout5buffer <- mkClockBUFG(clocked_by pll.clkout5);
      clkout5_buf = clkout5buffer;
   end
   else begin
      clkout5_buf = pll.clkout5;
   end

   if (params.clkout6_buffer) begin
      Clock clkout6buffer <- mkClockBUFG(clocked_by pll.clkout6);
      clkout6_buf = clkout6buffer;
   end
   else begin
      clkout6_buf = pll.clkout6;
   end

   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////

   interface Clock        clkout0   = clkout0_buf;
   interface Clock        clkout0_n = clkout0n_buf;
   interface Clock        clkout1   = clkout1_buf;
   interface Clock        clkout1_n = clkout1n_buf;
   interface Clock        clkout2   = clkout2_buf;
   interface Clock        clkout2_n = clkout2n_buf;
   interface Clock        clkout3   = clkout3_buf;
   interface Clock        clkout3_n = clkout3n_buf;
   interface Clock        clkout4   = clkout4_buf;
   interface Clock        clkout5   = clkout5_buf;
   interface Clock        clkout6   = clkout6_buf;
   method    Bool         locked    = pll.locked;
   interface Clock        clkfbout = pll.clkfbout;
   method                 clkfbin = pll.clkfbin;
endmodule: mkClockGenerator7Adv

////////////////////////////////////////////////////////////

(* always_ready, always_enabled *)
interface IbufdsTest;
   (* prefix="" *)	  
   method Action in(Bit#(1) i, Bit#(1) ib);
   interface ReadOnly#(Bit#(1)) o;
endinterface

module mkIbufdsTest(IbufdsTest);
   Wire#(Bit#(1)) i_w <- mkDWire(0);
   Wire#(Bit#(1)) ib_w <- mkDWire(0);
   ReadOnly#(Bit#(1)) ibufds <- mkIBUFDS(i_w, ib_w);

   method Action in(Bit#(1) i, Bit#(1) ib);
       i_w <= i;
       ib_w <= ib;
   endmethod
   interface ReadOnly o = ibufds;
endmodule

(* always_ready, always_enabled *)
interface BIBUF#(numeric type sa);
    interface Inout#(Bit#(sa))     pad;
endinterface
import "BVI" GenBIBUF =
module mkBIBUF#(Inout#(a) v)(BIBUF#(sa)) provisos(Bits#(a, sa));
    let sa = fromInteger(valueOf(sa));
    parameter SIZE=sa;
    default_clock clk();
    default_reset rst();
    inout IO = v;
    ifc_inout pad(PAD);
endmodule

(* always_ready, always_enabled *)
interface IOBUF;
    method Bit#(1)            o();
    interface Inout#(Bit#(1)) io;
endinterface
import "BVI" IOBUF =
module mkIOBUF#(Bit#(1) t, Bit#(1) i)(IOBUF);
    default_clock clk();
    default_reset rst();
    port I = i;
    port T = t;
    method O o();
    ifc_inout io(IO);
    schedule (o) CF (o);
endmodule

