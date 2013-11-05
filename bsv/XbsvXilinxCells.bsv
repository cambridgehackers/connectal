
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
module vMkClockIBUFDS#(Wire#(one_bit) i, Wire#(one_bit) ib)(ClockGenIfc) provisos(Bits#(one_bit,1));
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
endmodule: vMkClockIBUFDS

module mkClockIBUFDS#(Wire#(one_bit) i, Wire#(one_bit) ib)(Clock) provisos(Bits#(one_bit,1));
   let _m <- vMkClockIBUFDS(i, ib);
   return _m.gen_clk;
endmodule: mkClockIBUFDS

import "BVI" OBUFT =
module mkOBUFT#(Wire#(one_bit) i, Wire#(one_bit) t)(ReadOnly#(one_bit)) provisos(Bits#(one_bit,1));
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
   method Bit#(1) dataout();
endinterface

import "BVI" IDELAYE2 =
module mkIDELAYE2#(IDELAYE2_Config cfg, Clock serdes_clock)(IdelayE2);
   default_clock clk(C);
   default_reset rst(REGRST);
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
   method datain(DATAIN) enable((*inhigh*) en2);
   method idatain(IDATAIN) enable((*inhigh*) en3) clocked_by(serdes);

   schedule (datain, idatain, inc, ce) CF (datain, idatain, inc, ce);
   schedule (cntvalueout, dataout, ld, datain, ldpipeen, inc, cinvctrl, cntvaluein, ce, idatain) CF (cntvalueout, dataout, ld, datain, ldpipeen, inc, cinvctrl, cntvaluein, ce, idatain);
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

interface XbsvMMCME2;
   interface Clock     clkout0;
   interface Clock     clkout1;
   interface Clock     clkfbout;
   (* always_ready, always_enabled *)
   method    Bool      locked;
   (* always_enabled *)
   method    Action    clkfbin(Bit#(1) v);
endinterface

typedef struct {
   String      bandwidth;
   String      compensation;
   Real        clkfbout_mult_f;
   Real        clkfbout_phase;
   Real        clkin1_period;
   Real        clkin2_period;
   Integer     divclk_divide;
   Real        clkout0_divide_f;
   Real        clkout0_duty_cycle;
   Real        clkout0_phase;
   Integer     clkout1_divide;
   Real        clkout1_duty_cycle;
   Real        clkout1_phase;
   Real        ref_jitter1;
   Real        ref_jitter2;
} XbsvMMCMParams deriving (Bits, Eq);

import "BVI" MMCM_ADV =
module mkXbsvMMCM#(XbsvMMCMParams params)(XbsvMMCME2);
   //Reset reset <- exposeCurrentReset;
   //default_reset rst() = reset;
   no_reset;
   default_clock clk1(CLKIN1);
   parameter BANDWIDTH            = params.bandwidth;
   parameter COMPENSATION         = params.compensation;
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
   output_clock clkout0(CLKOUT0);
   output_clock clkout1(CLKOUT1);
   method LOCKED     locked()     clocked_by(no_clock) reset_by(no_reset);
   method            clkfbin(CLKFBIN) enable((*inhigh*)en1);
   schedule clkfbin C clkfbin;
   schedule locked CF (clkfbin, locked);
endmodule

(* always_ready, always_enabled *)
interface XbsvODDR#(type a);
   method    a            q();
   method    Action       s(Bool i);
   method    Action       ce(Bool i);
   method    Action       d1(a i);
   method    Action       d2(a i);
endinterface: XbsvODDR

import "BVI" ODDR =
module mkXbsvODDR#(ODDRParams#(a) params)(XbsvODDR#(a))
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
endmodule: mkXbsvODDR


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
