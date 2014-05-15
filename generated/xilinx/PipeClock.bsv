
/*
   ./scripts/importbvi.py
   -o
   PipeClock.bsv
   -P
   pclk
   -I
   pclk
   -p
   pcie_lane
   xilinx/7x/pcie/source/pcie_7x_0_pipe_clock.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface PclkClk#(numeric type pcie_lane);
    method Action      clk(Bit#(1) v);
    method Bit#(1)     dclk();
    method Action      gen3(Bit#(1) v);
    method Bit#(1)     mmcm_lock();
    method Bit#(1)     oobclk();
    method Bit#(1)     pclk();
    method Action      pclk_sel(Bit#(pcie_lane) v);
    method Action      pclk_sel_slave(Bit#(pcie_lane) v);
    method Bit#(1)     pclk_slave();
    method Action      rst_n(Bit#(1) v);
    method Action      rxoutclk_in(Bit#(pcie_lane) v);
    method Bit#(pcie_lane)     rxoutclk_out();
    method Bit#(1)     rxusrclk();
    method Action      txoutclk(Bit#(1) v);
    method Bit#(1)     userclk1();
    method Bit#(1)     userclk2();
endinterface
(* always_ready, always_enabled *)
interface pclk#(numeric type pcie_lane);
    interface PclkClk#(pcie_lane)     clk;
endinterface
import "BVI" pcie_7x_0_pipe_clock =
module mkpclk(pclk#(pcie_lane));
    let pcie_lane = valueOf(pcie_lane);
    default_clock clk();
    default_reset rst();
    interface PclkClk     clk;
        method clk(CLK_CLK) enable((*inhigh*) EN_CLK_CLK);
        method CLK_DCLK dclk();
        method gen3(CLK_GEN3) enable((*inhigh*) EN_CLK_GEN3);
        method CLK_MMCM_LOCK mmcm_lock();
        method CLK_OOBCLK oobclk();
        method CLK_PCLK pclk();
        method pclk_sel(CLK_PCLK_SEL) enable((*inhigh*) EN_CLK_PCLK_SEL);
        method pclk_sel_slave(CLK_PCLK_SEL_SLAVE) enable((*inhigh*) EN_CLK_PCLK_SEL_SLAVE);
        method CLK_PCLK_SLAVE pclk_slave();
        method rst_n(CLK_RST_N) enable((*inhigh*) EN_CLK_RST_N);
        method rxoutclk_in(CLK_RXOUTCLK_IN) enable((*inhigh*) EN_CLK_RXOUTCLK_IN);
        method CLK_RXOUTCLK_OUT rxoutclk_out();
        method CLK_RXUSRCLK rxusrclk();
        method txoutclk(CLK_TXOUTCLK) enable((*inhigh*) EN_CLK_TXOUTCLK);
        method CLK_USERCLK1 userclk1();
        method CLK_USERCLK2 userclk2();
    endinterface
    schedule (clk.clk, clk.dclk, clk.gen3, clk.mmcm_lock, clk.oobclk, clk.pclk, clk.pclk_sel, clk.pclk_sel_slave, clk.pclk_slave, clk.rst_n, clk.rxoutclk_in, clk.rxoutclk_out, clk.rxusrclk, clk.txoutclk, clk.userclk1, clk.userclk2) CF (clk.clk, clk.dclk, clk.gen3, clk.mmcm_lock, clk.oobclk, clk.pclk, clk.pclk_sel, clk.pclk_sel_slave, clk.pclk_slave, clk.rst_n, clk.rxoutclk_in, clk.rxoutclk_out, clk.rxusrclk, clk.txoutclk, clk.userclk1, clk.userclk2);
endmodule
