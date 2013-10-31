
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

interface IdelayE2;
   method Bit#(5) cntvalueout();
   method Action cinvctrl(Bit#(1) v);
   method Action cntvaluein(Bit#(5) v);
   method Action ld();
   method Action ldpipeen();
   method Action inc(Bool inc);
   method Action datain(Bit#(1) v);
   method Action idatain(Bit#(1) v);
   method Bit#(1) dataout();
endinterface

import "BVI" IDELAYE2 =
module mkIDELAYE2#(IDELAYE2_Config cfg)(IdelayE2);
   default_clock clk(C);
   default_reset rst(REGRST);

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

   method ld() enable(LD);

   // is LDPIPEEN the enable for DATAIN?
   method ldpipeen() enable(LDPIPEEN);

   method DATAOUT dataout();
   method inc(INC) enable(CE);
   method datain(DATAIN) enable((*inhigh*) en2);
   method idatain(IDATAIN) enable((*inhigh*) en3);

   schedule (datain, idatain, inc) CF (datain, idatain, inc);
   schedule (cntvalueout, dataout) CF (cntvalueout, dataout);
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
   interface ClockGenIfc oclk;
   interface ClockGenIfc oclkb;
endinterface

import "BVI" ISERDESE2 =
module mkISERDESE2#(ISERDESE2_Config cfg, Clock clk, Clock clkb)(IserdesE2);
   input_clock clk(CLK) = clk;
   input_clock clkb(CLKB) = clkb;
   default_clock clkdiv(CLKDIV);
   default_reset rst(RST);

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
   method dynclkdivsel(DYNCLKDIVSEL) enable ((*inhigh*) en7);
   method dynclksel(DYNCLKSEL) enable ((*inhigh*) en8);

   interface ClockGenIfc oclk;
      output_clock gen_clk(OCLK);
   endinterface
   interface ClockGenIfc oclkb;
      output_clock gen_clk(OCLKB);
   endinterface

   schedule (o, q1, q2, q3, q4, q5, q6, q7, q8, shiftout1, shiftout2) 
      CF (o, q1, q2, q3, q4, q5, q6, q7, q8, shiftout1, shiftout2);
   schedule (d, bitslip, ce1, ce2, ddly, shiftin1, shiftin2, ofb, dynclkdivsel, dynclksel)
      CF (d, bitslip, ce1, ce2, ddly, shiftin1, shiftin2, ofb, dynclkdivsel, dynclksel);   
endmodule
import "BVI" BUFR =
module vMkBUFR5(Wire#(one_bit))
   provisos(Bits#(one_bit, 1));
  
   default_clock clk();
   default_reset rstn();
  
   parameter BUFR_DIVIDE = "5";
  
   method       _write(I) enable((*inhigh*)en);
   method O     _read;

   port   CE = True;
   port   CLR = False;

   path(I, O);
  
   schedule _write SB _read;
   schedule _write C  _write;
   schedule _read  CF _read;
endmodule

module mkBUFR5(Wire#(a))
   provisos(Bits#(a, sa));

   Vector#(sa, Wire#(Bit#(1))) _bufr <- replicateM(vMkBUFR5);
  
   method a _read;
      return unpack(pack(readVReg(_bufr)));
   endmethod
  
   method Action _write(a x);
      writeVReg(_bufr, unpack(pack(x)));
   endmethod
endmodule

import "BVI" BUFIO =
module vMkBUFIO(Wire#(one_bit))
   provisos(Bits#(one_bit, 1));
  
   default_clock clk();
   default_reset rstn();
  
   method       _write(I) enable((*inhigh*)en);
   method O     _read;

   path(I, O);
  
   schedule _write SB _read;
   schedule _write C  _write;
   schedule _read  CF _read;
endmodule

module mkBUFIO(Wire#(a))
   provisos(Bits#(a, sa));

   Vector#(sa, Wire#(Bit#(1))) _bufr <- replicateM(vMkBUFIO);
  
   method a _read;
      return unpack(pack(readVReg(_bufr)));
   endmethod
  
   method Action _write(a x);
      writeVReg(_bufr, unpack(pack(x)));
   endmethod
endmodule

interface XbsvMMCME2;
   interface Clock     clkout0;
   //interface Clock     clkout0_n;
   interface Clock     clkout1;
   //interface Clock     clkout1_n;
   //interface Clock     clkout2;
   //interface Clock     clkout2_n;
   //interface Clock     clkout3;
   //interface Clock     clkout3_n;
   //interface Clock     clkout4;
   //interface Clock     clkout5;
   //interface Clock     clkout6;
   interface Clock     clkfbout;
   (* always_ready, always_enabled *)
   method    Bool      locked;
   (* always_enabled *)
   method    Action    clkfbin(Bit#(1) v);
endinterface

import "BVI" MMCM_ADV =
module mkXbsvMMCM#(MMCMParams params)(XbsvMMCME2);
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
