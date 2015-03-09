
/*
   ../../scripts/importbvi.py
   -o
   BviFpAdd.bsv
   -c
   aclk
   -f
   s_axis_a
   -f
   s_axis_b
   -f
   m_axis_result
   -I
   BviFpAdd
   -P
   BviFpAdd
   ../../generated/xilinx/zc706/fp_add/fp_add_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import FloatingPoint::*;

interface BviFpAdd;
   method Action s_axis_a(Float v);
   method Action s_axis_b(Float v);
   method Action s_axis_operation(Bit#(8) v);
   method ActionValue#(Float) m_axis_result();
endinterface

import "BVI" fp_add =
module mkBviFpAdd (BviFpAdd);
   default_clock aclk(aclk);
   default_reset aresetn(aresetn);
   
   method s_axis_a (s_axis_a_tdata)
      ready (s_axis_a_tready) enable (s_axis_a_tvalid);
   method s_axis_b (s_axis_b_tdata)
      ready (s_axis_b_tready) enable (s_axis_b_tvalid);
      
   method s_axis_operation (s_axis_operation_tdata)
      ready (s_axis_operation_tready) enable (s_axis_operation_tvalid);
      
   method m_axis_result_tdata m_axis_result ()
      ready (m_axis_result_tvalid) enable (m_axis_result_tready);
      
      schedule (s_axis_a, s_axis_b, s_axis_operation, m_axis_result) CF
      (s_axis_a, s_axis_b, s_axis_operation, m_axis_result);
endmodule
