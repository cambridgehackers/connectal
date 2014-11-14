/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

/*
   ../../generated/scripts/importbvi.py
   -o
   BviAurora.bsv
   -I
   BviAurora64
   -P
   Au64
   -n
   refclk1_in
   -n
   gt_qpllclk_quad2
   -n
   gt_qpllrefclk_quad2
   -c
   refclk1_in
   -r
   reset
   -c
   clk_in
   -c
   init_clk
   -c
   user_clk
   -c
   sync_clk
   ../../generated/xilinx/zc706/aurora_64b66b_0/aurora_64b66b_0_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface Au64Channel;
    method Bit#(1)     up();
endinterface
(* always_ready, always_enabled *)
interface Au64Do;
    method Action      cc(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Au64Drp;
    method Action      clk_in(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Au64Gt;
    method Bit#(1)     pll_lock();
    method Action      rxcdrovrden_in(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Au64Hard;
    method Bit#(1)     err();
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface Au64Lane;
    method Bit#(1)     up();
endinterface
(* always_ready, always_enabled *)
interface Au64Link;
    method Bit#(1)     reset_out();
endinterface
(* always_ready, always_enabled *)
interface Au64M_axi_rx;
    method Bit#(64)     tdata();
    method Bit#(8)     tkeep();
    method Bit#(1)     tlast();
    method Bit#(1)     tvalid();
endinterface
(* always_ready, always_enabled *)
interface Au64Mmcm;
    method Action      not_locked(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Au64Pma;
    method Action      init(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Au64Power;
    method Action      down(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Au64Reset;
    method Action      pb(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Au64S_axi;
    method Action      araddr(Bit#(32) v);
    method Bit#(1)     arready();
    method Action      arvalid(Bit#(1) v);
    method Action      awaddr(Bit#(32) v);
    method Bit#(1)     awready();
    method Action      awvalid(Bit#(1) v);
    method Action      bready(Bit#(1) v);
    method Bit#(1)     bvalid();
    method Bit#(32)     rdata();
    method Action      rready(Bit#(1) v);
    method Bit#(1)     rvalid();
    method Action      wdata(Bit#(32) v);
    method Bit#(1)     wready();
    method Action      wvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Au64S_axi_tx;
    method Action      tdata(Bit#(64) v);
    method Action      tkeep(Bit#(8) v);
    method Action      tlast(Bit#(1) v);
    method Bit#(1)     tready();
    method Action      tvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Au64Soft;
    method Bit#(1)     err();
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface Au64Sys;
    method Bit#(1)     reset_out();
endinterface
(* always_ready, always_enabled *)
interface Au64Tx;
    method Bit#(1)     out_clk();
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface BviAurora64;
    interface Au64Channel     channel;
    interface Au64Do     do_;
    interface Au64Drp     drp;
    interface Au64Gt     gt;
    method Action      gt_qpllclk_quad2_in(Bit#(1) v);
    method Action      gt_qpllrefclk_quad2_in(Bit#(1) v);
    interface Au64Hard     hard;
    interface Au64Lane     lane;
    interface Au64Link     link;
    method Action      loopback(Bit#(3) v);
    interface Au64M_axi_rx     m_axi_rx;
    interface Au64Mmcm     mmcm;
    interface Au64Pma     pma;
    interface Au64Power     power;
    interface Au64Reset     reset;
    method Action      rxn(Bit#(1) v);
    method Action      rxp(Bit#(1) v);
    interface Au64S_axi     s_axi;
    interface Au64S_axi_tx     s_axi_tx;
    interface Au64Soft     soft;
    interface Au64Sys     sys;
    interface Au64Tx     tx;
    method Bit#(1)     txn();
    method Bit#(1)     txp();
endinterface
import "BVI" aurora_64b66b_0 =
module mkBviAurora64#(Clock init_clk, Clock refclk1_in, Clock sync_clk, Clock user_clk, Reset init_clk_reset, Reset refclk1_in_reset, Reset reset, Reset sync_clk_reset, Reset user_clk_reset)(BviAurora64);
    default_clock clk();
    default_reset rst();
        input_clock init_clk(init_clk) = init_clk;
        input_reset init_clk_reset() = init_clk_reset; /* from clock*/
    input_clock refclk1_in(refclk1_in) = refclk1_in;
    input_reset refclk1_in_reset() = refclk1_in_reset; /* from clock*/
    input_reset reset(reset) = reset;
        input_clock sync_clk(sync_clk) = sync_clk;
        input_reset sync_clk_reset() = sync_clk_reset; /* from clock*/
        input_clock user_clk(user_clk) = user_clk;
        input_reset user_clk_reset() = user_clk_reset; /* from clock*/
    interface Au64Channel     channel;
        method channel_up up();
    endinterface
   interface Au64Do     do_;
        method cc(do_cc) enable((*inhigh*) EN_do_cc);
    endinterface
    interface Au64Drp     drp;
        method clk_in(drp_clk_in) enable((*inhigh*) EN_drp_clk_in);
    endinterface
    interface Au64Gt     gt;
        method gt_pll_lock pll_lock();
        method rxcdrovrden_in(gt_rxcdrovrden_in) enable((*inhigh*) EN_gt_rxcdrovrden_in);
    endinterface
    method gt_qpllclk_quad2_in(gt_qpllclk_quad2_in) enable((*inhigh*) EN_gt_qpllclk_quad2_in);
    method gt_qpllrefclk_quad2_in(gt_qpllrefclk_quad2_in) enable((*inhigh*) EN_gt_qpllrefclk_quad2_in);
    interface Au64Hard     hard;
        method hard_err err();
    endinterface
    interface Au64Lane     lane;
        method lane_up up();
    endinterface
    interface Au64Link     link;
        method link_reset_out reset_out();
    endinterface
    method loopback(loopback) enable((*inhigh*) EN_loopback);
    interface Au64M_axi_rx     m_axi_rx;
        method m_axi_rx_tdata tdata();
        method m_axi_rx_tkeep tkeep();
        method m_axi_rx_tlast tlast();
        method m_axi_rx_tvalid tvalid();
    endinterface
    interface Au64Mmcm     mmcm;
        method not_locked(mmcm_not_locked) enable((*inhigh*) EN_mmcm_not_locked);
    endinterface
    interface Au64Pma     pma;
        method init(pma_init) enable((*inhigh*) EN_pma_init);
    endinterface
    interface Au64Power     power;
        method down(power_down) enable((*inhigh*) EN_power_down);
    endinterface
    interface Au64Reset     reset;
        method pb(reset_pb) enable((*inhigh*) EN_reset_pb);
    endinterface
    method rxn(rxn) enable((*inhigh*) EN_rxn);
    method rxp(rxp) enable((*inhigh*) EN_rxp);
    interface Au64S_axi     s_axi;
        method araddr(s_axi_araddr) enable((*inhigh*) EN_s_axi_araddr);
        method s_axi_arready arready();
        method arvalid(s_axi_arvalid) enable((*inhigh*) EN_s_axi_arvalid);
        method awaddr(s_axi_awaddr) enable((*inhigh*) EN_s_axi_awaddr);
        method s_axi_awready awready();
        method awvalid(s_axi_awvalid) enable((*inhigh*) EN_s_axi_awvalid);
        method bready(s_axi_bready) enable((*inhigh*) EN_s_axi_bready);
        method s_axi_bvalid bvalid();
        method s_axi_rdata rdata();
        method rready(s_axi_rready) enable((*inhigh*) EN_s_axi_rready);
        method s_axi_rvalid rvalid();
        method wdata(s_axi_wdata) enable((*inhigh*) EN_s_axi_wdata);
        method s_axi_wready wready();
        method wvalid(s_axi_wvalid) enable((*inhigh*) EN_s_axi_wvalid);
    endinterface
    interface Au64S_axi_tx     s_axi_tx;
        method tdata(s_axi_tx_tdata) enable((*inhigh*) EN_s_axi_tx_tdata);
        method tkeep(s_axi_tx_tkeep) enable((*inhigh*) EN_s_axi_tx_tkeep);
        method tlast(s_axi_tx_tlast) enable((*inhigh*) EN_s_axi_tx_tlast);
        method s_axi_tx_tready tready();
        method tvalid(s_axi_tx_tvalid) enable((*inhigh*) EN_s_axi_tx_tvalid);
    endinterface
    interface Au64Soft     soft;
        method soft_err err();
    endinterface
    interface Au64Sys     sys;
        method sys_reset_out reset_out();
    endinterface
    interface Au64Tx     tx;
        method tx_out_clk out_clk() clocked_by (user_clk);
    endinterface
    method txn txn();
    method txp txp();
    schedule (channel.up, do_.cc, drp.clk_in, gt.pll_lock, gt.rxcdrovrden_in, gt_qpllclk_quad2_in, gt_qpllrefclk_quad2_in, hard.err, lane.up, link.reset_out, loopback, m_axi_rx.tdata, m_axi_rx.tkeep, m_axi_rx.tlast, m_axi_rx.tvalid, mmcm.not_locked, pma.init, power.down, reset.pb, rxn, rxp, s_axi.araddr, s_axi.arready, s_axi.arvalid, s_axi.awaddr, s_axi.awready, s_axi.awvalid, s_axi.bready, s_axi.bvalid, s_axi.rdata, s_axi.rready, s_axi.rvalid, s_axi.wdata, s_axi.wready, s_axi.wvalid, s_axi_tx.tdata, s_axi_tx.tkeep, s_axi_tx.tlast, s_axi_tx.tready, s_axi_tx.tvalid, soft.err, sys.reset_out, tx.out_clk, txn, txp) CF (channel.up, do_.cc, drp.clk_in, gt.pll_lock, gt.rxcdrovrden_in, gt_qpllclk_quad2_in, gt_qpllrefclk_quad2_in, hard.err, lane.up, link.reset_out, loopback, m_axi_rx.tdata, m_axi_rx.tkeep, m_axi_rx.tlast, m_axi_rx.tvalid, mmcm.not_locked, pma.init, power.down, reset.pb, rxn, rxp, s_axi.araddr, s_axi.arready, s_axi.arvalid, s_axi.awaddr, s_axi.awready, s_axi.awvalid, s_axi.bready, s_axi.bvalid, s_axi.rdata, s_axi.rready, s_axi.rvalid, s_axi.wdata, s_axi.wready, s_axi.wvalid, s_axi_tx.tdata, s_axi_tx.tkeep, s_axi_tx.tlast, s_axi_tx.tready, s_axi_tx.tvalid, soft.err, sys.reset_out, tx.out_clk, txn, txp);
endmodule
