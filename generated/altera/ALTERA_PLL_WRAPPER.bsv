
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
   -f
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
    method Bit#(1)     clk_1();
endinterface
(* always_ready, always_enabled *)
interface PciePllWrap;
    method Bit#(1)     locked();
    interface PciepllwrapOut     out;
    method Action      rst(Bit#(1) v);
endinterface
import "BVI" altera_pll_wrapper( =
module mkPciePllWrap#(Clock refclk, Reset refclk_reset)(PciePllWrap);
    default_clock clk();
    default_reset rst();
    input_clock refclk(refclk) = refclk;
    input_reset refclk_reset() = refclk_reset; /* from clock*/
    method locked locked();
    interface PciepllwrapOut     out;
        method outclk_0 clk_0();
        method outclk_1 clk_1();
    endinterface
    method rst(rst) enable((*inhigh*) EN_rst);
    schedule (locked, out.clk_0, out.clk_1, rst) CF (locked, out.clk_0, out.clk_1, rst);
endmodule
