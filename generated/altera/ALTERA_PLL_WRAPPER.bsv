
/*
   ./importbvi.py
   -o
   ALTERA_PLL_WRAPPER.bsv
   -I
   PciePllWrap
   -P
   PciePllWrap
   -c
   refclk
   -r
   rst
   -f
   out
   -f
   locked
   ../../out/de5/synthesis/altera_pll_wrapper.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface PciepllwrapOut;
    method Bit#(1)     clk_0();
endinterface
(* always_ready, always_enabled *)
interface PciePllWrap;
    method Bit#(1)     locked();
    interface PciepllwrapOut     out;
endinterface
import "BVI" altera_pll_wrapper =
module mkPciePllWrap#(Clock refclk, Reset refclk_reset, Reset rst)(PciePllWrap);
    default_clock clk();
    default_reset rst();
    input_clock refclk(refclk) = refclk;
    input_reset refclk_reset() = refclk_reset; /* from clock*/
    input_reset reset(rst) = rst;
    method locked locked();
    interface PciepllwrapOut     out;
        method outclk_0 clk_0();
    endinterface
    schedule (locked, out.clk_0) CF (locked, out.clk_0);
endmodule
