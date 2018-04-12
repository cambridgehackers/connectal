
/*
   /home/jamey/connectal/generated/scripts/importbvi.py
   -o
   VaddBvi.bsv
   -P
   VaddBvi
   -I
   VaddBvi
   -c
   ap_clk
   -r
   ap_rst
   verilog/vectoradd.v
   -n
   in0
   -n
   in1
   -n
   out
   -n
   ap
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;
import FIFOF::*;

(* always_ready, always_enabled *)
interface VaddBvi;
    method Bit#(1)     ap_done();
    method Bit#(1)     ap_idle();
    method Bit#(1)     ap_ready();
    method Action      ap_start(Bit#(1) v);
    method Action      in0(Bit#(32) v);
    method Bit#(1)     in0_ap_ack();
    method Action      in0_ap_vld(Bit#(1) v);
    method Action      in1(Bit#(32) v);
    method Bit#(1)     in1_ap_ack();
    method Action      in1_ap_vld(Bit#(1) v);
    method Bit#(32)     out_r();
    method Action      out_r_ap_ack(Bit#(1) v);
    method Bit#(1)     out_r_ap_vld();
endinterface
import "BVI" vectoradd =
module mkVaddBvi(VaddBvi);
   Clock ap_clk <- exposeCurrentClock;
   Reset reset <- exposeCurrentReset;
   Reset ap_rst <- mkResetInverter(reset);
    default_clock ap_clk(ap_clk) = ap_clk;
    default_reset ap_rst(ap_rst) = ap_rst;
    method ap_done ap_done();
    method ap_idle ap_idle();
    method ap_ready ap_ready();
    method ap_start(ap_start) enable((*inhigh*) EN_ap_start);
    method in0(in0) enable((*inhigh*) EN_in0);
    method in0_ap_ack in0_ap_ack();
    method in0_ap_vld(in0_ap_vld) enable((*inhigh*) EN_in0_ap_vld);
    method in1(in1) enable((*inhigh*) EN_in1);
    method in1_ap_ack in1_ap_ack();
    method in1_ap_vld(in1_ap_vld) enable((*inhigh*) EN_in1_ap_vld);
    method out_r out_r();
    method out_r_ap_ack(out_r_ap_ack) enable((*inhigh*) EN_out_r_ap_ack);
    method out_r_ap_vld out_r_ap_vld();
    schedule (ap_done, ap_idle, ap_ready, ap_start, in0, in0_ap_ack, in0_ap_vld, in1, in1_ap_ack, in1_ap_vld, out_r, out_r_ap_ack, out_r_ap_vld) CF (ap_done, ap_idle, ap_ready, ap_start, in0, in0_ap_ack, in0_ap_vld, in1, in1_ap_ack, in1_ap_vld, out_r, out_r_ap_ack, out_r_ap_vld);
endmodule

// This wrapper was written by hand but could be generated from the
// HLS-generated Verilog by knowing its conventions for generating
// module interfaces
interface Vaddhls;
   interface Put#(Bit#(32)) in0;
   interface Put#(Bit#(32)) in1;
   interface Get#(Bit#(32)) out;
   method Action start();
   method ActionValue#(Bit#(1)) done();
endinterface

module mkVaddhls#(Integer fifoDepth)(Vaddhls);
   VaddBvi vadd <- mkVaddBvi();
   
   FIFOF#(Bit#(32)) in0Fifo <- mkSizedFIFOF(fifoDepth);
   FIFOF#(Bit#(32)) in1Fifo <- mkSizedFIFOF(fifoDepth);
   FIFOF#(Bit#(32)) outFifo <- mkSizedFIFOF(fifoDepth);

   rule rl_in0_data;
      $display("in0 %d", in0Fifo.first);
      vadd.in0(in0Fifo.first);
   endrule
   rule rl_in0_hs;
      vadd.in0_ap_vld(pack(in0Fifo.notEmpty()));
      if (vadd.in0_ap_ack() == 1)
	 in0Fifo.deq();
   endrule
   rule rl_in1_data;
      $display("in1 %d", in1Fifo.first);
      vadd.in1(in1Fifo.first);
   endrule
   rule rl_in1_hs;
      vadd.in1_ap_vld(pack(in1Fifo.notEmpty()));
      if (vadd.in1_ap_ack() == 1)
	 in1Fifo.deq();
   endrule
   rule rl_out_data;
      if (vadd.out_r_ap_vld() == 1) begin
	 outFifo.enq(vadd.out_r());
	 $display("out %d", vadd.out_r());
      end
   endrule
   rule rl_out_hs;
      vadd.out_r_ap_ack(pack(vadd.out_r_ap_vld() == 1 && outFifo.notFull()));
   endrule

   interface Put in0 = toPut(in0Fifo);
   interface Put in1 = toPut(in1Fifo);
   interface Get out = toGet(outFifo);

   method Action start() if (vadd.ap_ready == 1);
      vadd.ap_start(1);
   endmethod

   method ActionValue#(Bit#(1)) done() if (vadd.ap_done == 1);
      return 1;
   endmethod

endmodule
