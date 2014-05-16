
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
    method Action      i0(Bit#(1) v);
    method Action      i1(Bit#(1) v);
    method Action      ignore0(Bit#(1) v);
    method Action      ignore1(Bit#(1) v);
    method Bit#(1)     o();
    method Action      s0(Bit#(1) v);
    method Action      s1(Bit#(1) v);
endinterface
import "BVI" BUFGCTRL =
module mkBufgctrl(Bufgctrl);
    default_clock clk();
    default_reset rst();
    method ce0(CE0) enable((*inhigh*) EN_CE0);
    method ce1(CE1) enable((*inhigh*) EN_CE1);
    method i0(I0) enable((*inhigh*) EN_I0);
    method i1(I1) enable((*inhigh*) EN_I1);
    method ignore0(IGNORE0) enable((*inhigh*) EN_IGNORE0);
    method ignore1(IGNORE1) enable((*inhigh*) EN_IGNORE1);
    method O o();
    method s0(S0) enable((*inhigh*) EN_S0);
    method s1(S1) enable((*inhigh*) EN_S1);
    schedule (ce0, ce1, i0, i1, ignore0, ignore1, o, s0, s1) CF (ce0, ce1, i0, i1, ignore0, ignore1, o, s0, s1);
endmodule
