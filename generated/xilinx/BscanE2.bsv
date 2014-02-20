
/*
   scripts/importbvi.py
   -o
   bscane2.bsv
   -C
   BSCANE2
   -I
   BscanE2
   -c
   DRCK
   -c
   TCK
   --param=JTAG_CHAIN
   /scratch/Xilinx/Vivado/2013.2/data/parts/xilinx/zynq/zynq.lib
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface BscanE2;
    interface Clock    tck;
    interface Clock    drck;
    interface Reset    reset;

    method Bit#(1)     capture();
    method Bit#(1)     runtest();
    method Bit#(1)     sel();
    method Bit#(1)     shift();
    method Bit#(1)     tdi();
    method Action      tdo(Bit#(1) v);
    method Bit#(1)     tms();
    method Bit#(1)     update();
endinterface
import "BVI" BSCANE2 =
module mkBscanE2#(Integer jtag_chain)(BscanE2);
    parameter JTAG_CHAIN = jtag_chain;
    default_clock clk();
    default_reset rst();
    output_clock drck(DRCK);
    output_clock tck(TCK);
    output_reset reset(RESET) clocked_by(tck);

    method CAPTURE capture() clocked_by (tck) reset_by (reset);
    method RUNTEST runtest() clocked_by (tck) reset_by (reset);
    method SEL sel() clocked_by (tck) reset_by (reset);
    method SHIFT shift() clocked_by (tck) reset_by (reset);
    method TDI tdi() clocked_by (tck) reset_by (reset);
    method tdo(TDO) enable((*inhigh*) EN_TDO) clocked_by (tck) reset_by (reset);
    method TMS tms() clocked_by (tck) reset_by (reset);
    method UPDATE update() clocked_by (tck) reset_by (reset);
    schedule (capture, runtest, sel, shift, tdi, tdo, tms, update) CF (capture, runtest, sel, shift, tdi, tdo, tms, update);
endmodule
