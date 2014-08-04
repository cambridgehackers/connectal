
/*
   /home/jamey/xbsv/scripts/importbvi.py
   -o
   FpMul.bsv
   -c
   aclk
   -f
   s_axis_a
   -f
   s_axis_b
   -f
   m_axis_result
   -I
   FpMul
   -P
   FpMul
   fp_mul_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface FpmulM_axis_result;
    method Bit#(32)     tdata();
    method Action      tready(Bit#(1) v);
    method Bit#(1)     tvalid();
endinterface
(* always_ready, always_enabled *)
interface FpmulS_axis_a;
    method Action      tdata(Bit#(32) v);
    method Bit#(1)     tready();
    method Action      tvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface FpmulS_axis_b;
    method Action      tdata(Bit#(32) v);
    method Bit#(1)     tready();
    method Action      tvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface FpMul;
    interface FpmulM_axis_result     m_axis_result;
    interface FpmulS_axis_a     s_axis_a;
    interface FpmulS_axis_b     s_axis_b;
endinterface
import "BVI" fp_mul =
module mkFpMul(FpMul);
    default_clock aclk(aclk);
    default_reset aresetn(aresetn);
    interface FpmulM_axis_result     m_axis_result;
        method m_axis_result_tdata tdata();
        method tready(m_axis_result_tready) enable((*inhigh*) EN_m_axis_result_tready);
        method m_axis_result_tvalid tvalid();
    endinterface
    interface FpmulS_axis_a     s_axis_a;
        method tdata(s_axis_a_tdata) enable((*inhigh*) EN_s_axis_a_tdata);
        method s_axis_a_tready tready();
        method tvalid(s_axis_a_tvalid) enable((*inhigh*) EN_s_axis_a_tvalid);
    endinterface
    interface FpmulS_axis_b     s_axis_b;
        method tdata(s_axis_b_tdata) enable((*inhigh*) EN_s_axis_b_tdata);
        method s_axis_b_tready tready();
        method tvalid(s_axis_b_tvalid) enable((*inhigh*) EN_s_axis_b_tvalid);
    endinterface
    schedule (m_axis_result.tdata, m_axis_result.tready, m_axis_result.tvalid, s_axis_a.tdata, s_axis_a.tready, s_axis_a.tvalid, s_axis_b.tdata, s_axis_b.tready, s_axis_b.tvalid) CF (m_axis_result.tdata, m_axis_result.tready, m_axis_result.tvalid, s_axis_a.tdata, s_axis_a.tready, s_axis_a.tvalid, s_axis_b.tdata, s_axis_b.tready, s_axis_b.tvalid);
endmodule
