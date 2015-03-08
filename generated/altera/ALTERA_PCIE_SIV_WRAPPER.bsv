
/*
   ./importbvi.py
   -o
   ALTERA_PCIE_SIV_WRAPPER.bsv
   -I
   PcieS4Wrap
   -P
   PcieS4Wrap
   -r
   pin_perst
   -r
   npor
   -r
   reset_status
   -r
   pcie_rstn
   -r
   srstn
   -c
   refclk
   -c
   core_clk_out
   -c
   pclk_in
   -c
   reconfig_clk
   -c
   clk250_out
   -f
   app
   -f
   pex_msi
   -f
   cpl
   -f
   rx_st
   -f
   tx_st
   -f
   fixedclk
   -f
   lmi
   -f
   tx
   -f
   rx
   -f
   phystatus
   -f
   pipe
   -f
   pm
   -f
   pme
   -f
   reconfig
   -f
   test
   -f
   lane
   -f
   ltssm
   -f
   powerdown
   -f
   rate
   -f
   rc_pll
   -f
   tl_cfg
   ../../out/htg4/siv_gen2x8/siv_gen2x8_examples/chaining_dma/siv_gen2x8_plus.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface Pcies4wrapApp;
    method Bit#(1)     int_ack();
    method Action      int_sts(Bit#(1) v);
    method Bit#(1)     msi_ack();
    method Action      msi_num(Bit#(5) v);
    method Action      msi_req(Bit#(1) v);
    method Action      msi_tc(Bit#(3) v);
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapClk250;
    method Bit#(1)     out;
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapClk500;
    method Bit#(1)     out;
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapCore;
    interface Clock     clk_out;
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapCpl;
    method Action      err(Bit#(7) v);
    method Action      pending(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapSrstn;
    method Reset     stn();
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapLane;
    method Bit#(4)     act();
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapLmi;
    method Bit#(1)     ack();
    method Action      addr(Bit#(12) v);
    method Action      din(Bit#(32) v);
    method Bit#(32)     dout();
    method Action      rden(Bit#(1) v);
    method Action      wren(Bit#(1) v);
endinterface
interface Pcies4wrapPclk;
    method Action      in(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapLtssm;
    method Bit#(5)     sm();
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapPex_msi;
    method Action      num(Bit#(5) v);
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapPhystatus;
    method Action      ext(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapPipe;
    method Action      mode(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapPld;
    method Action      clk(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapPm_e;
    method Action      vent(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapPm;
    method Action      auxpwr(Bit#(1) v);
    method Action      data(Bit#(10) v);
    method Action      e_to_cr(Bit#(1) v);
    method Bit#(1)     e_to_sr();
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapPowerdown;
    method Bit#(2)     ext();
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapRate;
    method Bit#(1)     ext();
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapRc_pll;
    method Bit#(1)     locked();
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapReconfig;
    method Action      clk_locked(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapRx;
    method Action      in0(Bit#(1) v);
    method Action      in1(Bit#(1) v);
    method Action      in2(Bit#(1) v);
    method Action      in3(Bit#(1) v);
    method Action      in4(Bit#(1) v);
    method Action      in5(Bit#(1) v);
    method Action      in6(Bit#(1) v);
    method Action      in7(Bit#(1) v);
    method Action      data0_ext(Bit#(8) v);
    method Action      data1_ext(Bit#(8) v);
    method Action      data2_ext(Bit#(8) v);
    method Action      data3_ext(Bit#(8) v);
    method Action      data4_ext(Bit#(8) v);
    method Action      data5_ext(Bit#(8) v);
    method Action      data6_ext(Bit#(8) v);
    method Action      data7_ext(Bit#(8) v);
    method Action      datak0_ext(Bit#(1) v);
    method Action      datak1_ext(Bit#(1) v);
    method Action      datak2_ext(Bit#(1) v);
    method Action      datak3_ext(Bit#(1) v);
    method Action      datak4_ext(Bit#(1) v);
    method Action      datak5_ext(Bit#(1) v);
    method Action      datak6_ext(Bit#(1) v);
    method Action      datak7_ext(Bit#(1) v);
    method Action      elecidle0_ext(Bit#(1) v);
    method Action      elecidle1_ext(Bit#(1) v);
    method Action      elecidle2_ext(Bit#(1) v);
    method Action      elecidle3_ext(Bit#(1) v);
    method Action      elecidle4_ext(Bit#(1) v);
    method Action      elecidle5_ext(Bit#(1) v);
    method Action      elecidle6_ext(Bit#(1) v);
    method Action      elecidle7_ext(Bit#(1) v);
    method Bit#(1)     polarity0_ext();
    method Bit#(1)     polarity1_ext();
    method Bit#(1)     polarity2_ext();
    method Bit#(1)     polarity3_ext();
    method Bit#(1)     polarity4_ext();
    method Bit#(1)     polarity5_ext();
    method Bit#(1)     polarity6_ext();
    method Bit#(1)     polarity7_ext();
    method Action      status0_ext(Bit#(3) v);
    method Action      status1_ext(Bit#(3) v);
    method Action      status2_ext(Bit#(3) v);
    method Action      status3_ext(Bit#(3) v);
    method Action      status4_ext(Bit#(3) v);
    method Action      status5_ext(Bit#(3) v);
    method Action      status6_ext(Bit#(3) v);
    method Action      status7_ext(Bit#(3) v);
    method Action      valid0_ext(Bit#(1) v);
    method Action      valid1_ext(Bit#(1) v);
    method Action      valid2_ext(Bit#(1) v);
    method Action      valid3_ext(Bit#(1) v);
    method Action      valid4_ext(Bit#(1) v);
    method Action      valid5_ext(Bit#(1) v);
    method Action      valid6_ext(Bit#(1) v);
    method Action      valid7_ext(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapRx_st;
    method Bit#(8)     bardec0();
    method Bit#(16)     be0();
    method Bit#(128)     data0();
    method Bit#(1)     empty0();
    method Bit#(1)     eop0();
    method Bit#(1)     err0();
    method Action      mask0(Bit#(1) v);
    method Action      ready0(Bit#(1) v);
    method Bit#(1)     sop0();
    method Bit#(1)     valid0();
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapTest;
    method Action      in(Bit#(40) v);
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapTl_cfg;
    method Bit#(4)     add();
    method Bit#(32)     ctl();
    method Bit#(1)     ctl_wr();
    method Bit#(53)     sts();
    method Bit#(1)     sts_wr();
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapTx;
    method Bit#(36)     cred0();
    method Bit#(1)     fifo_empty0();
    method Bit#(1)     out0();
    method Bit#(1)     out1();
    method Bit#(1)     out2();
    method Bit#(1)     out3();
    method Bit#(1)     out4();
    method Bit#(1)     out5();
    method Bit#(1)     out6();
    method Bit#(1)     out7();
    method Bit#(1)     compl0_ext();
    method Bit#(1)     compl1_ext();
    method Bit#(1)     compl2_ext();
    method Bit#(1)     compl3_ext();
    method Bit#(1)     compl4_ext();
    method Bit#(1)     compl5_ext();
    method Bit#(1)     compl6_ext();
    method Bit#(1)     compl7_ext();
    method Bit#(8)     data0_ext();
    method Bit#(8)     data1_ext();
    method Bit#(8)     data2_ext();
    method Bit#(8)     data3_ext();
    method Bit#(8)     data4_ext();
    method Bit#(8)     data5_ext();
    method Bit#(8)     data6_ext();
    method Bit#(8)     data7_ext();
    method Bit#(1)     datak0_ext();
    method Bit#(1)     datak1_ext();
    method Bit#(1)     datak2_ext();
    method Bit#(1)     datak3_ext();
    method Bit#(1)     datak4_ext();
    method Bit#(1)     datak5_ext();
    method Bit#(1)     datak6_ext();
    method Bit#(1)     datak7_ext();
    method Bit#(1)     detectrx_ext();
    method Bit#(1)     elecidle0_ext();
    method Bit#(1)     elecidle1_ext();
    method Bit#(1)     elecidle2_ext();
    method Bit#(1)     elecidle3_ext();
    method Bit#(1)     elecidle4_ext();
    method Bit#(1)     elecidle5_ext();
    method Bit#(1)     elecidle6_ext();
    method Bit#(1)     elecidle7_ext();
endinterface
(* always_ready, always_enabled *)
interface Pcies4wrapTx_st;
    method Action      data0(Bit#(128) v);
    method Action      empty0(Bit#(1) v);
    method Action      eop0(Bit#(1) v);
    method Action      err0(Bit#(1) v);
    method Bit#(1)     ready0();
    method Action      sop0(Bit#(1) v);
    method Action      valid0(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PcieS4Wrap;
    interface Pcies4wrapApp     app;
    interface Pcies4wrapClk250     clk250;
    interface Pcies4wrapClk500     clk500;
    interface Pcies4wrapCore     core;
    interface Pcies4wrapCpl     cpl;
    interface Pcies4wrapSrstn   sr;
    interface Pcies4wrapLane     lane;
    interface Pcies4wrapPclk     pclk;
    interface Pcies4wrapLmi     lmi;
    interface Pcies4wrapLtssm     lts;
    interface Pcies4wrapPex_msi     pex_msi;
    interface Pcies4wrapPhystatus     phystatus;
    interface Pcies4wrapPipe     pipe;
    interface PciewrapPm_e     pm_e;
    interface Pcies4wrapPm     pm;
    interface Pcies4wrapPowerdown     powerdown;
    interface Pcies4wrapRate     rate;
    interface Pcies4wrapRc_pll     rc_pll;
    interface Pcies4wrapReconfig     reconfig;
    interface Pcies4wrapRx     rx;
    interface Pcies4wrapRx_st     rx_st;
    interface Pcies4wrapTest     test;
    interface Pcies4wrapTl_cfg     tl_cfg;
    interface Pcies4wrapTx     tx;
    interface Pcies4wrapTx_st     tx_st;
endinterface
import "BVI" siv_gen2x8_plus =
module mkPcieS4Wrap#(Clock refclk, Clock reconfig_clk, Clock fixedclk_serdes, Clock pld_clk, Reset pcie_rstn, Reset local_rstn)(PcieS4Wrap);
    default_clock clk();
    default_reset rst();
    input_reset pcie_rstn(pcie_rstn) = pcie_rstn;
    input_reset local_rstn(local_rstn) = local_rstn;
    input_clock fixedclk_serdes(fixedclk_serdes) = fixedclk_serdes;
    input_clock pld_clk(pld_clk) = pld_clk;
    input_clock reconfig_clk(reconfig_clk) = reconfig_clk;
    input_clock refclk(refclk) = refclk;
    interface Pcies4wrapApp     app;
        method app_int_ack int_ack();
        method int_sts(app_int_sts) enable((*inhigh*) EN_app_int_sts);
        method app_msi_ack msi_ack();
        method msi_num(app_msi_num) enable((*inhigh*) EN_app_msi_num);
        method msi_req(app_msi_req) enable((*inhigh*) EN_app_msi_req);
        method msi_tc(app_msi_tc) enable((*inhigh*) EN_app_msi_tc);
    endinterface
    interface Pcies4wrapClk250     clk250;
        method clk250_out out();
    endinterface
    interface Pcies4wrapClk500     clk500;
        method clk500_out out();
    endinterface
    interface Pcies4wrapCore     core;
        output_clock clk_out(core_clk_out);
    endinterface
    interface Pcies4wrapCpl     cpl;
        method err(cpl_err) enable((*inhigh*) EN_cpl_err);
        method pending(cpl_pending) enable((*inhigh*) EN_cpl_pending);
    endinterface
    interface Pcies4wrapLane     lane;
        method lane_act act();
    endinterface
    interface Pcies4wrapLmi     lmi;
        method lmi_ack ack();
        method addr(lmi_addr) enable((*inhigh*) EN_lmi_addr);
        method din(lmi_din) enable((*inhigh*) EN_lmi_din);
        method lmi_dout dout();
        method rden(lmi_rden) enable((*inhigh*) EN_lmi_rden);
        method wren(lmi_wren) enable((*inhigh*) EN_lmi_wren);
    endinterface
    interface Pcies4wrapPclk     pclk;
        method in(pclk_in) enable((*inhigh*) EN_pclk_in);
    endinterface
    interface Pcies4wrapLtssm lts;
        method ltssm sm();
    endinterface
    interface Pcies4wrapPex_msi     pex_msi;
        method num(pex_msi_num) enable((*inhigh*) EN_pex_msi_num);
    endinterface
    interface Pcies4wrapPhystatus     phystatus;
        method ext(phystatus_ext) enable((*inhigh*) EN_phystatus_ext);
    endinterface
    interface Pcies4wrapPipe     pipe;
        method mode(pipe_mode) enable((*inhigh*) EN_pipe_mode);
    endinterface
    interface PciewrapPm_e     pm_e;
        method vent(pm_event) enable((*inhigh*) EN_pm_event);
    endinterface
    interface Pcies4wrapPm     pm;
        method auxpwr(pm_auxpwr) enable((*inhigh*) EN_pm_auxpwr);
        method data(pm_data) enable((*inhigh*) EN_pm_data);
        method e_to_cr(pm_e_to_cr) enable((*inhigh*) EN_pm_e_to_cr);
        method pm_e_to_sr e_to_sr();
    endinterface
    interface Pcies4wrapPowerdown     powerdown;
        method powerdown_ext ext();
    endinterface
    interface Pcies4wrapRate     rate;
        method rate_ext ext();
    endinterface
    interface Pcies4wrapRc_pll     rc_pll;
        method rc_pll_locked locked();
    endinterface
    interface Pcies4wrapReconfig     reconfig;
        method clk_locked(reconfig_clk_locked) clocked_by (reconfig_clk) enable((*inhigh*) EN_reconfig_clk_locked);
    endinterface
    interface Pcies4wrapRx     rx;
        method in0(rx_in0) enable((*inhigh*) EN_rx_in0);
        method in1(rx_in1) enable((*inhigh*) EN_rx_in1);
        method in2(rx_in2) enable((*inhigh*) EN_rx_in2);
        method in3(rx_in3) enable((*inhigh*) EN_rx_in3);
        method in4(rx_in4) enable((*inhigh*) EN_rx_in4);
        method in5(rx_in5) enable((*inhigh*) EN_rx_in5);
        method in6(rx_in6) enable((*inhigh*) EN_rx_in6);
        method in7(rx_in7) enable((*inhigh*) EN_rx_in7);
        method data0_ext(rx_data0_ext) enable((*inhigh*) EN_rx_data0_ext);
        method data1_ext(rx_data1_ext) enable((*inhigh*) EN_rx_data1_ext);
        method data2_ext(rx_data2_ext) enable((*inhigh*) EN_rx_data2_ext);
        method data3_ext(rx_data3_ext) enable((*inhigh*) EN_rx_data3_ext);
        method data4_ext(rx_data4_ext) enable((*inhigh*) EN_rx_data4_ext);
        method data5_ext(rx_data5_ext) enable((*inhigh*) EN_rx_data5_ext);
        method data6_ext(rx_data6_ext) enable((*inhigh*) EN_rx_data6_ext);
        method data7_ext(rx_data7_ext) enable((*inhigh*) EN_rx_data7_ext);
        method datak0_ext(rx_datak0_ext) enable((*inhigh*) EN_rx_datak0_ext);
        method datak1_ext(rx_datak1_ext) enable((*inhigh*) EN_rx_datak1_ext);
        method datak2_ext(rx_datak2_ext) enable((*inhigh*) EN_rx_datak2_ext);
        method datak3_ext(rx_datak3_ext) enable((*inhigh*) EN_rx_datak3_ext);
        method datak4_ext(rx_datak4_ext) enable((*inhigh*) EN_rx_datak4_ext);
        method datak5_ext(rx_datak5_ext) enable((*inhigh*) EN_rx_datak5_ext);
        method datak6_ext(rx_datak6_ext) enable((*inhigh*) EN_rx_datak6_ext);
        method datak7_ext(rx_datak7_ext) enable((*inhigh*) EN_rx_datak7_ext);
        method elecidle0_ext(rx_elecidle0_ext) enable((*inhigh*) EN_rx_elecidle0_ext);
        method elecidle1_ext(rx_elecidle1_ext) enable((*inhigh*) EN_rx_elecidle1_ext);
        method elecidle2_ext(rx_elecidle2_ext) enable((*inhigh*) EN_rx_elecidle2_ext);
        method elecidle3_ext(rx_elecidle3_ext) enable((*inhigh*) EN_rx_elecidle3_ext);
        method elecidle4_ext(rx_elecidle4_ext) enable((*inhigh*) EN_rx_elecidle4_ext);
        method elecidle5_ext(rx_elecidle5_ext) enable((*inhigh*) EN_rx_elecidle5_ext);
        method elecidle6_ext(rx_elecidle6_ext) enable((*inhigh*) EN_rx_elecidle6_ext);
        method elecidle7_ext(rx_elecidle7_ext) enable((*inhigh*) EN_rx_elecidle7_ext);
        method rx_polarity0_ext polarity0_ext();
        method rx_polarity1_ext polarity1_ext();
        method rx_polarity2_ext polarity2_ext();
        method rx_polarity3_ext polarity3_ext();
        method rx_polarity4_ext polarity4_ext();
        method rx_polarity5_ext polarity5_ext();
        method rx_polarity6_ext polarity6_ext();
        method rx_polarity7_ext polarity7_ext();
        method status0_ext(rx_status0_ext) enable((*inhigh*) EN_rx_status0_ext);
        method status1_ext(rx_status1_ext) enable((*inhigh*) EN_rx_status1_ext);
        method status2_ext(rx_status2_ext) enable((*inhigh*) EN_rx_status2_ext);
        method status3_ext(rx_status3_ext) enable((*inhigh*) EN_rx_status3_ext);
        method status4_ext(rx_status4_ext) enable((*inhigh*) EN_rx_status4_ext);
        method status5_ext(rx_status5_ext) enable((*inhigh*) EN_rx_status5_ext);
        method status6_ext(rx_status6_ext) enable((*inhigh*) EN_rx_status6_ext);
        method status7_ext(rx_status7_ext) enable((*inhigh*) EN_rx_status7_ext);
        method valid0_ext(rx_valid0_ext) enable((*inhigh*) EN_rx_valid0_ext);
        method valid1_ext(rx_valid1_ext) enable((*inhigh*) EN_rx_valid1_ext);
        method valid2_ext(rx_valid2_ext) enable((*inhigh*) EN_rx_valid2_ext);
        method valid3_ext(rx_valid3_ext) enable((*inhigh*) EN_rx_valid3_ext);
        method valid4_ext(rx_valid4_ext) enable((*inhigh*) EN_rx_valid4_ext);
        method valid5_ext(rx_valid5_ext) enable((*inhigh*) EN_rx_valid5_ext);
        method valid6_ext(rx_valid6_ext) enable((*inhigh*) EN_rx_valid6_ext);
        method valid7_ext(rx_valid7_ext) enable((*inhigh*) EN_rx_valid7_ext);
    endinterface
    interface Pcies4wrapRx_st     rx_st;
        method rx_st_bardec0 bardec0();
        method rx_st_be0 be0();
        method rx_st_data0 data0();
        method rx_st_empty0 empty0();
        method rx_st_eop0 eop0();
        method rx_st_err0 err0();
        method mask0(rx_st_mask0) enable((*inhigh*) EN_rx_st_mask0);
        method ready0(rx_st_ready0) enable((*inhigh*) EN_rx_st_ready0);
        method rx_st_sop0 sop0();
        method rx_st_valid0 valid0();
    endinterface
    interface Pcies4wrapSrstn   sr;
        output_reset stn(srstn);
    endinterface
    interface Pcies4wrapTest     test;
        method in(test_in) enable((*inhigh*) EN_test_in);
    endinterface
    interface Pcies4wrapTl_cfg     tl_cfg;
        method tl_cfg_add add();
        method tl_cfg_ctl ctl();
        method tl_cfg_ctl_wr ctl_wr();
        method tl_cfg_sts sts();
        method tl_cfg_sts_wr sts_wr();
    endinterface
    interface Pcies4wrapTx     tx;
        method tx_cred0 cred0();
        method tx_fifo_empty0 fifo_empty0();
        method tx_out0 out0();
        method tx_out1 out1();
        method tx_out2 out2();
        method tx_out3 out3();
        method tx_out4 out4();
        method tx_out5 out5();
        method tx_out6 out6();
        method tx_out7 out7();
        method tx_compl0_ext compl0_ext();
        method tx_compl1_ext compl1_ext();
        method tx_compl2_ext compl2_ext();
        method tx_compl3_ext compl3_ext();
        method tx_compl4_ext compl4_ext();
        method tx_compl5_ext compl5_ext();
        method tx_compl6_ext compl6_ext();
        method tx_compl7_ext compl7_ext();
        method tx_data0_ext data0_ext();
        method tx_data1_ext data1_ext();
        method tx_data2_ext data2_ext();
        method tx_data3_ext data3_ext();
        method tx_data4_ext data4_ext();
        method tx_data5_ext data5_ext();
        method tx_data6_ext data6_ext();
        method tx_data7_ext data7_ext();
        method tx_datak0_ext datak0_ext();
        method tx_datak1_ext datak1_ext();
        method tx_datak2_ext datak2_ext();
        method tx_datak3_ext datak3_ext();
        method tx_datak4_ext datak4_ext();
        method tx_datak5_ext datak5_ext();
        method tx_datak6_ext datak6_ext();
        method tx_datak7_ext datak7_ext();
        method tx_detectrx_ext detectrx_ext();
        method tx_elecidle0_ext elecidle0_ext();
        method tx_elecidle1_ext elecidle1_ext();
        method tx_elecidle2_ext elecidle2_ext();
        method tx_elecidle3_ext elecidle3_ext();
        method tx_elecidle4_ext elecidle4_ext();
        method tx_elecidle5_ext elecidle5_ext();
        method tx_elecidle6_ext elecidle6_ext();
        method tx_elecidle7_ext elecidle7_ext();
    endinterface
    interface Pcies4wrapTx_st     tx_st;
        method data0(tx_st_data0) enable((*inhigh*) EN_tx_st_data0);
        method empty0(tx_st_empty0) enable((*inhigh*) EN_tx_st_empty0);
        method eop0(tx_st_eop0) enable((*inhigh*) EN_tx_st_eop0);
        method err0(tx_st_err0) enable((*inhigh*) EN_tx_st_err0);
        method tx_st_ready0 ready0();
        method sop0(tx_st_sop0) enable((*inhigh*) EN_tx_st_sop0);
        method valid0(tx_st_valid0) enable((*inhigh*) EN_tx_st_valid0);
    endinterface
    schedule (app.int_ack, app.int_sts, app.msi_ack, app.msi_num, app.msi_req, app.msi_tc, cpl.err, cpl.pending, lane.act, lmi.ack, lmi.addr, lmi.din, lmi.dout, lmi.rden, lmi.wren, lts.sm, clk250.out, clk500.out, pclk.in, pex_msi.num, phystatus.ext, pipe.mode, pm.auxpwr, pm.data, pm_e.vent, pm.e_to_cr, pm.e_to_sr, powerdown.ext, rate.ext, rc_pll.locked, reconfig.clk_locked, rx.in0, rx.in1, rx.in2, rx.in3, rx.in4, rx.in5, rx.in6, rx.in7, rx.data0_ext, rx.data1_ext, rx.data2_ext, rx.data3_ext, rx.data4_ext, rx.data5_ext, rx.data6_ext, rx.data7_ext, rx.datak0_ext, rx.datak1_ext, rx.datak2_ext, rx.datak3_ext, rx.datak4_ext, rx.datak5_ext, rx.datak6_ext, rx.datak7_ext, rx.elecidle0_ext, rx.elecidle1_ext, rx.elecidle2_ext, rx.elecidle3_ext, rx.elecidle4_ext, rx.elecidle5_ext, rx.elecidle6_ext, rx.elecidle7_ext, rx.polarity0_ext, rx.polarity1_ext, rx.polarity2_ext, rx.polarity3_ext, rx.polarity4_ext, rx.polarity5_ext, rx.polarity6_ext, rx.polarity7_ext, rx.status0_ext, rx.status1_ext, rx.status2_ext, rx.status3_ext, rx.status4_ext, rx.status5_ext, rx.status6_ext, rx.status7_ext, rx.valid0_ext, rx.valid1_ext, rx.valid2_ext, rx.valid3_ext, rx.valid4_ext, rx.valid5_ext, rx.valid6_ext, rx.valid7_ext, rx_st.bardec0, rx_st.be0, rx_st.data0, rx_st.empty0, rx_st.eop0, rx_st.err0, rx_st.mask0, rx_st.ready0, rx_st.sop0, rx_st.valid0, test.in, tl_cfg.add, tl_cfg.ctl, tl_cfg.ctl_wr, tl_cfg.sts, tl_cfg.sts_wr, tx.cred0, tx.fifo_empty0, tx.out0, tx.out1, tx.out2, tx.out3, tx.out4, tx.out5, tx.out6, tx.out7, tx.compl0_ext, tx.compl1_ext, tx.compl2_ext, tx.compl3_ext, tx.compl4_ext, tx.compl5_ext, tx.compl6_ext, tx.compl7_ext, tx.data0_ext, tx.data1_ext, tx.data2_ext, tx.data3_ext, tx.data4_ext, tx.data5_ext, tx.data6_ext, tx.data7_ext, tx.datak0_ext, tx.datak1_ext, tx.datak2_ext, tx.datak3_ext, tx.datak4_ext, tx.datak5_ext, tx.datak6_ext, tx.datak7_ext, tx.detectrx_ext, tx.elecidle0_ext, tx.elecidle1_ext, tx.elecidle2_ext, tx.elecidle3_ext, tx.elecidle4_ext, tx.elecidle5_ext, tx.elecidle6_ext, tx.elecidle7_ext, tx_st.data0, tx_st.empty0, tx_st.eop0, tx_st.err0, tx_st.ready0, tx_st.sop0, tx_st.valid0) CF (app.int_ack, app.int_sts, app.msi_ack, app.msi_num, app.msi_req, app.msi_tc, cpl.err, cpl.pending, lane.act, lmi.ack, lmi.addr, lmi.din, lmi.dout, lmi.rden, lmi.wren, lts.sm, clk250.out, clk500.out, pclk.in, pex_msi.num, phystatus.ext, pipe.mode, pm.auxpwr, pm.data, pm_e.vent, pm.e_to_cr, pm.e_to_sr, powerdown.ext, rate.ext, rc_pll.locked, reconfig.clk_locked, rx.in0, rx.in1, rx.in2, rx.in3, rx.in4, rx.in5, rx.in6, rx.in7, rx.data0_ext, rx.data1_ext, rx.data2_ext, rx.data3_ext, rx.data4_ext, rx.data5_ext, rx.data6_ext, rx.data7_ext, rx.datak0_ext, rx.datak1_ext, rx.datak2_ext, rx.datak3_ext, rx.datak4_ext, rx.datak5_ext, rx.datak6_ext, rx.datak7_ext, rx.elecidle0_ext, rx.elecidle1_ext, rx.elecidle2_ext, rx.elecidle3_ext, rx.elecidle4_ext, rx.elecidle5_ext, rx.elecidle6_ext, rx.elecidle7_ext, rx.polarity0_ext, rx.polarity1_ext, rx.polarity2_ext, rx.polarity3_ext, rx.polarity4_ext, rx.polarity5_ext, rx.polarity6_ext, rx.polarity7_ext, rx.status0_ext, rx.status1_ext, rx.status2_ext, rx.status3_ext, rx.status4_ext, rx.status5_ext, rx.status6_ext, rx.status7_ext, rx.valid0_ext, rx.valid1_ext, rx.valid2_ext, rx.valid3_ext, rx.valid4_ext, rx.valid5_ext, rx.valid6_ext, rx.valid7_ext, rx_st.bardec0, rx_st.be0, rx_st.data0, rx_st.empty0, rx_st.eop0, rx_st.err0, rx_st.mask0, rx_st.ready0, rx_st.sop0, rx_st.valid0, test.in, tl_cfg.add, tl_cfg.ctl, tl_cfg.ctl_wr, tl_cfg.sts, tl_cfg.sts_wr, tx.cred0, tx.fifo_empty0, tx.out0, tx.out1, tx.out2, tx.out3, tx.out4, tx.out5, tx.out6, tx.out7, tx.compl0_ext, tx.compl1_ext, tx.compl2_ext, tx.compl3_ext, tx.compl4_ext, tx.compl5_ext, tx.compl6_ext, tx.compl7_ext, tx.data0_ext, tx.data1_ext, tx.data2_ext, tx.data3_ext, tx.data4_ext, tx.data5_ext, tx.data6_ext, tx.data7_ext, tx.datak0_ext, tx.datak1_ext, tx.datak2_ext, tx.datak3_ext, tx.datak4_ext, tx.datak5_ext, tx.datak6_ext, tx.datak7_ext, tx.detectrx_ext, tx.elecidle0_ext, tx.elecidle1_ext, tx.elecidle2_ext, tx.elecidle3_ext, tx.elecidle4_ext, tx.elecidle5_ext, tx.elecidle6_ext, tx.elecidle7_ext, tx_st.data0, tx_st.empty0, tx_st.eop0, tx_st.err0, tx_st.ready0, tx_st.sop0, tx_st.valid0);
endmodule
