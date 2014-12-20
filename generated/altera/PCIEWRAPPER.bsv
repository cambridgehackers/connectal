
/*
   ./importbvi.py
   -o
   PCIEWRAPPER.bsv
   -I
   PcieWrap
   -P
   PcieWrap
   -r
   pin_perst
   -r
   npor
   -r
   reset_status
   -c
   pld_clk
   -c
   refclk
   -c
   coreclkout_hip
   -n
   serdes_pll_locked
   -n
   pld_core_ready
   -n
   pld_clk_inuse
   -n
   dlup
   -n
   dlup_exit
   -n
   ev128ns
   -n
   ev1us
   -n
   hotrst_exit
   -n
   l2_exit
   -n
   currentspeed
   -n
   ltssmstate
   -n
   derr_cor_ext_rcv
   -n
   derr_cor_ext_rpl
   -n
   derr_rpl
   -f
   app
   -f
   int_status
   -f
   aer_msi_num
   -f
   pex_msi_num
   -f
   serr_out
   -f
   cpl_err
   -f
   cpl_pending
   -f
   cpl_err_func
   -f
   tl
   -f
   lmi
   -n
   pm
   -f
   tx_st
   -f
   rx_st
   -f
   rx
   -f
   tx
   -n
   txdata
   -n
   txdatak
   -n
   txdetectrx
   -n
   txelecidle
   -n
   txcompl
   -n
   tx_cred
   -n
   txdeemph
   -n
   txmargin
   -n
   txswing
   -n
   rxpolarity
   -n
   powerdown
   -n
   rxdata
   -n
   rxvalid
   -n
   rxdatak
   -n
   rxelecidle
   -n
   rxstatus
   -n
   eidleinfersel
   -n
   powerdown
   -n
   phystatus
   -n
   sim_pipe_pclk_in
   -n
   sim_pipe_rate
   -n
   sim_ltssmstate
   -n
   simu_mode_pipe
   -n
   test_in
   -n
   simu_mode_pipe
   -n
   lane_act
   -n
   testin_zero
   ../../out/de5/synthesis/altera_pcie_sv_hip_ast.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface PciewrapApp;
    method Bit#(1)     int_ack();
    method Action      int_sts(Bit#(1) v);
    method Bit#(1)     msi_ack();
    method Action      msi_num(Bit#(5) v);
    method Action      msi_req(Bit#(1) v);
    method Action      msi_tc(Bit#(3) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapCfg;
    method Bit#(1)     par_err();
endinterface
(* always_ready, always_enabled *)
interface PciewrapCoreclkout;
    interface Clock     hip;
endinterface
(* always_ready, always_enabled *)
interface PciewrapCpl;
    method Action      err(Bit#(7) v);
    method Action      pending(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapHpg;
    method Action      ctrler(Bit#(5) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapKo;
    method Bit#(12)     cpl_spc_data();
    method Bit#(8)     cpl_spc_header();
endinterface
(* always_ready, always_enabled *)
interface PciewrapLmi;
    method Bit#(1)     ack();
    method Action      addr(Bit#(12) v);
    method Action      din(Bit#(32) v);
    method Bit#(32)     dout();
    method Action      rden(Bit#(1) v);
    method Action      wren(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface PciewrapReconfig;
    method Bit#(460)     from_xcvr();
    method Action      to_xcvr(Bit#(700) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapReset;
    method Reset     status();
endinterface
(* always_ready, always_enabled *)
interface PciewrapRx;
    method Action      in0(Bit#(1) v);
    method Action      in1(Bit#(1) v);
    method Action      in2(Bit#(1) v);
    method Action      in3(Bit#(1) v);
    method Action      in4(Bit#(1) v);
    method Action      in5(Bit#(1) v);
    method Action      in6(Bit#(1) v);
    method Action      in7(Bit#(1) v);
    method Bit#(1)     par_err();
endinterface
(* always_ready, always_enabled *)
interface PciewrapRx_st;
    method Bit#(8)     bar();
    method Bit#(128)     data();
    method Bit#(2)     empty();
    method Bit#(1)     eop();
    method Bit#(1)     err();
    method Action      mask(Bit#(1) v);
    method Action      ready(Bit#(1) v);
    method Bit#(1)     sop();
    method Bit#(1)     valid();
endinterface
(* always_ready, always_enabled *)
interface PciewrapTl;
    method Bit#(4)     cfg_add();
    method Bit#(32)     cfg_ctl();
    method Bit#(53)     cfg_sts();
endinterface
(* always_ready, always_enabled *)
interface PciewrapTx;
    method Bit#(1)     out0();
    method Bit#(1)     out1();
    method Bit#(1)     out2();
    method Bit#(1)     out3();
    method Bit#(1)     out4();
    method Bit#(1)     out5();
    method Bit#(1)     out6();
    method Bit#(1)     out7();
    method Bit#(2)     par_err();
endinterface
(* always_ready, always_enabled *)
interface PciewrapTx_st;
    method Action      data(Bit#(128) v);
    method Action      empty(Bit#(2) v);
    method Action      eop(Bit#(1) v);
    method Action      err(Bit#(1) v);
    method Bit#(1)     ready();
    method Action      sop(Bit#(1) v);
    method Action      valid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PcieWrap;
    interface PciewrapApp     app;
    interface PciewrapCfg     cfg;
    interface PciewrapCoreclkout     coreclkout;
    interface PciewrapCpl     cpl;
    interface PciewrapHpg     hpg;
    interface PciewrapKo     ko;
    interface PciewrapLmi     lmi;
    interface PciewrapReconfig     reconfig;
    interface PciewrapReset     reset;
    interface PciewrapRx     rx;
    interface PciewrapRx_st     rx_st;
    interface PciewrapTl     tl;
    interface PciewrapTx     tx;
    interface PciewrapTx_st     tx_st;
endinterface
import "BVI" altera_pcie_sv_hip_ast =
module mkPcieWrap#(Clock pld_clk, Reset pin_perst, Reset pld_clk_reset)(PcieWrap);
    default_clock clk();
    default_reset rst();
        input_reset pin_perst(pin_perst) = pin_perst;
        input_clock pld_clk(pld_clk) = pld_clk;
        input_reset pld_clk_reset() = pld_clk_reset; /* from clock*/
    interface PciewrapApp     app;
        method appint_ack int_ack();
        method int_sts(appint_sts) enable((*inhigh*) EN_appint_sts);
        method appmsi_ack msi_ack();
        method msi_num(appmsi_num) enable((*inhigh*) EN_appmsi_num);
        method msi_req(appmsi_req) enable((*inhigh*) EN_appmsi_req);
        method msi_tc(appmsi_tc) enable((*inhigh*) EN_appmsi_tc);
    endinterface
    interface PciewrapCfg     cfg;
        method cfg_par_err par_err();
    endinterface
    interface PciewrapCoreclkout     coreclkout;
        output_clock hip(coreclkout_hip);
    endinterface
    interface PciewrapCpl     cpl;
        method err(cpl_err) enable((*inhigh*) EN_cpl_err);
        method pending(cpl_pending) enable((*inhigh*) EN_cpl_pending);
    endinterface
    interface PciewrapHpg     hpg;
        method ctrler(hpg_ctrler) enable((*inhigh*) EN_hpg_ctrler);
    endinterface
    interface PciewrapKo     ko;
        method ko_cpl_spc_data cpl_spc_data();
        method ko_cpl_spc_header cpl_spc_header();
    endinterface
    interface PciewrapLmi     lmi;
        method lmiack ack();
        method addr(lmiaddr) enable((*inhigh*) EN_lmiaddr);
        method din(lmidin) enable((*inhigh*) EN_lmidin);
        method lmidout dout();
        method rden(lmirden) enable((*inhigh*) EN_lmirden);
        method wren(lmiwren) enable((*inhigh*) EN_lmiwren);
    endinterface
    interface PciewrapReconfig     reconfig;
        method reconfig_from_xcvr from_xcvr();
        method to_xcvr(reconfig_to_xcvr) enable((*inhigh*) EN_reconfig_to_xcvr);
    endinterface
    interface PciewrapReset     reset;
        output_reset status(reset_status);
    endinterface
    interface PciewrapRx     rx;
        method in0(rxin0) enable((*inhigh*) EN_rxin0);
        method in1(rxin1) enable((*inhigh*) EN_rxin1);
        method in2(rxin2) enable((*inhigh*) EN_rxin2);
        method in3(rxin3) enable((*inhigh*) EN_rxin3);
        method in4(rxin4) enable((*inhigh*) EN_rxin4);
        method in5(rxin5) enable((*inhigh*) EN_rxin5);
        method in6(rxin6) enable((*inhigh*) EN_rxin6);
        method in7(rxin7) enable((*inhigh*) EN_rxin7);
        method rxpar_err par_err();
    endinterface
    interface PciewrapRx_st     rx_st;
        method rx_stbar bar();
        method rx_stdata data();
        method rx_stempty empty();
        method rx_steop eop();
        method rx_sterr err();
        method mask(rx_stmask) enable((*inhigh*) EN_rx_stmask);
        method ready(rx_stready) enable((*inhigh*) EN_rx_stready);
        method rx_stsop sop();
        method rx_stvalid valid();
    endinterface
    interface PciewrapTl     tl;
        method tlcfg_add cfg_add();
        method tlcfg_ctl cfg_ctl();
        method tlcfg_sts cfg_sts();
    endinterface
    interface PciewrapTx     tx;
        method txout0 out0();
        method txout1 out1();
        method txout2 out2();
        method txout3 out3();
        method txout4 out4();
        method txout5 out5();
        method txout6 out6();
        method txout7 out7();
        method txpar_err par_err();
    endinterface
    interface PciewrapTx_st     tx_st;
        method data(tx_stdata) enable((*inhigh*) EN_tx_stdata);
        method empty(tx_stempty) enable((*inhigh*) EN_tx_stempty);
        method eop(tx_steop) enable((*inhigh*) EN_tx_steop);
        method err(tx_sterr) enable((*inhigh*) EN_tx_sterr);
        method tx_stready ready();
        method sop(tx_stsop) enable((*inhigh*) EN_tx_stsop);
        method valid(tx_stvalid) enable((*inhigh*) EN_tx_stvalid);
    endinterface
    schedule (app.int_ack, app.int_sts, app.msi_ack, app.msi_num, app.msi_req, app.msi_tc, cfg.par_err, cpl.err, cpl.pending, hpg.ctrler, ko.cpl_spc_data, ko.cpl_spc_header, lmi.ack, lmi.addr, lmi.din, lmi.dout, lmi.rden, lmi.wren, reconfig.from_xcvr, reconfig.to_xcvr, rx.in0, rx.in1, rx.in2, rx.in3, rx.in4, rx.in5, rx.in6, rx.in7, rx.par_err, rx_st.bar, rx_st.data, rx_st.empty, rx_st.eop, rx_st.err, rx_st.mask, rx_st.ready, rx_st.sop, rx_st.valid, tl.cfg_add, tl.cfg_ctl, tl.cfg_sts, tx.out0, tx.out1, tx.out2, tx.out3, tx.out4, tx.out5, tx.out6, tx.out7, tx.par_err, tx_st.data, tx_st.empty, tx_st.eop, tx_st.err, tx_st.ready, tx_st.sop, tx_st.valid) CF (app.int_ack, app.int_sts, app.msi_ack, app.msi_num, app.msi_req, app.msi_tc, cfg.par_err, cpl.err, cpl.pending, hpg.ctrler, ko.cpl_spc_data, ko.cpl_spc_header, lmi.ack, lmi.addr, lmi.din, lmi.dout, lmi.rden, lmi.wren, reconfig.from_xcvr, reconfig.to_xcvr, rx.in0, rx.in1, rx.in2, rx.in3, rx.in4, rx.in5, rx.in6, rx.in7, rx.par_err, rx_st.bar, rx_st.data, rx_st.empty, rx_st.eop, rx_st.err, rx_st.mask, rx_st.ready, rx_st.sop, rx_st.valid, tl.cfg_add, tl.cfg_ctl, tl.cfg_sts, tx.out0, tx.out1, tx.out2, tx.out3, tx.out4, tx.out5, tx.out6, tx.out7, tx.par_err, tx_st.data, tx_st.empty, tx_st.eop, tx_st.err, tx_st.ready, tx_st.sop, tx_st.valid);
endmodule

(* synthesize *)
module test #(Clock pld_clk, Reset pin_perst, Reset pld_clk_reset) ();
   PcieWrap i <- mkPcieWrap(pld_clk, pin_perst, pld_clk_reset);
endmodule
