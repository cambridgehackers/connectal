
/*
   scripts/importbvi.py
   -o
   Bufgctrl.bsv
   -C
   BUFGCTRL
   -I
   Bufgctrl
   -P
   Bufgctrl
   -c
   I0
   -c
   I1
   -c
   O
   ../../import_components/Xilinx/Vivado/2013.2/data/parts/xilinx/zynq/zynq.lib
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface Bufgctrl;
    method Action      ce0(Bit#(1) v);
    method Action      ce1(Bit#(1) v);
    method Action      ignore0(Bit#(1) v);
    method Action      ignore1(Bit#(1) v);
    interface Clock     o;
    method Action      s0(Bit#(1) v);
    method Action      s1(Bit#(1) v);
endinterface
import "BVI" BUFGCTRL =
module mkBufgctrl#(Clock i0, Reset i0_reset, Clock i1, Reset i1_reset)(Bufgctrl);
    default_clock clk();
    default_reset rst();
    input_clock i0(I0) = i0;
    input_reset i0_reset() = i0_reset;
    input_clock i1(I1) = i1;
    input_reset i1_reset() = i1_reset;
    method ce0(CE0) enable((*inhigh*) EN_CE0);
    method ce1(CE1) enable((*inhigh*) EN_CE1);
    method ignore0(IGNORE0) enable((*inhigh*) EN_IGNORE0);
    method ignore1(IGNORE1) enable((*inhigh*) EN_IGNORE1);
    output_clock o(O);
    method s0(S0) clocked_by(o) enable((*inhigh*) EN_S0);
    method s1(S1) clocked_by(o) enable((*inhigh*) EN_S1);
    schedule (ce0, ce1, ignore0, ignore1, s0, s1) CF (ce0, ce1, ignore0, ignore1, s0, s1);
endmodule
