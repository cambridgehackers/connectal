
/*
   ./importbvi.py
   -o
   ALTERA_PCIE_SV_WRAPPER.bsv
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
   refclk
   -c
   coreclkout_hip
   -f
   serdes
   -f
   pld
   -f
   dl
   -f
   ev128
   -f
   ev1
   -f
   hotrst
   -f
   l2
   -f
   current
   -f
   derr
   -f
   lane
   -f
   ltssm
   -f
   reconfig
   -f
   tx_cred
   -f
   tx_par
   -f
   tx_s
   -f
   txd
   -f
   txe
   -f
   txc
   -f
   txm
   -f
   txs
   -f
   tx
   -f
   tx_cred
   -f
   rx_par
   -f
   rx_s
   -f
   rxd
   -f
   rxr
   -f
   rxe
   -f
   rxp
   -f
   rxs
   -f
   rxv
   -f
   rx
   -f
   cfg_par
   -f
   eidle
   -f
   power
   -f
   phy
   -f
   int_s
   -f
   cpl
   -f
   tl
   -f
   pm_e
   -f
   pme
   -f
   pm
   -f
   simu
   -f
   sim
   -f
   test_in
   ../../out/de5/synthesis/altera_pcie_sv_hip_ast_wrapper.v
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
interface PciewrapCfg_par;
    method Bit#(1)     err();
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
interface PciewrapCurrent;
    method Bit#(2)     speed();
endinterface
(* always_ready, always_enabled *)
interface PciewrapDerr;
    method Bit#(1)     cor_ext_rcv();
    method Bit#(1)     cor_ext_rpl();
    method Bit#(1)     rpl();
endinterface
(* always_ready, always_enabled *)
interface PciewrapDl;
    method Bit#(1)     up();
    method Bit#(1)     up_exit();
endinterface
(* always_ready, always_enabled *)
interface PciewrapEidle;
    method Bit#(3)     infersel0();
    method Bit#(3)     infersel1();
    method Bit#(3)     infersel2();
    method Bit#(3)     infersel3();
    method Bit#(3)     infersel4();
    method Bit#(3)     infersel5();
    method Bit#(3)     infersel6();
    method Bit#(3)     infersel7();
endinterface
(* always_ready, always_enabled *)
interface PciewrapEv1;
    method Bit#(1)     us();
endinterface
(* always_ready, always_enabled *)
interface PciewrapEv128;
    method Bit#(1)     ns();
endinterface
(* always_ready, always_enabled *)
interface PciewrapHotrst;
    method Bit#(1)     exit();
endinterface
(* always_ready, always_enabled *)
interface PciewrapHpg;
    method Action      ctrler(Bit#(5) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapInt_s;
    method Bit#(4)     tatus();
endinterface
(* always_ready, always_enabled *)
interface PciewrapKo;
    method Bit#(12)     cpl_spc_data();
    method Bit#(8)     cpl_spc_header();
endinterface
(* always_ready, always_enabled *)
interface PciewrapL2;
    method Bit#(1)     exit();
endinterface
(* always_ready, always_enabled *)
interface PciewrapLane;
    method Bit#(4)     act();
endinterface
(* always_ready, always_enabled *)
interface PciewrapLtssm;
    method Bit#(5)     state();
endinterface
(* always_ready, always_enabled *)
interface PciewrapPhy;
    method Action      status0(Bit#(1) v);
    method Action      status1(Bit#(1) v);
    method Action      status2(Bit#(1) v);
    method Action      status3(Bit#(1) v);
    method Action      status4(Bit#(1) v);
    method Action      status5(Bit#(1) v);
    method Action      status6(Bit#(1) v);
    method Action      status7(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface PciewrapPld;
    method Action      clk(Bit#(1) v);
    method Bit#(1)     clk_inuse();
    method Action      core_ready(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapPm;
    method Action      auxpwr(Bit#(1) v);
    method Action      data(Bit#(10) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapPm_e;
    method Action      vent(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapPme;
    method Action      to_cr(Bit#(1) v);
    method Bit#(1)     to_sr();
endinterface
(* always_ready, always_enabled *)
interface PciewrapPower;
    method Bit#(2)     down0();
    method Bit#(2)     down1();
    method Bit#(2)     down2();
    method Bit#(2)     down3();
    method Bit#(2)     down4();
    method Bit#(2)     down5();
    method Bit#(2)     down6();
    method Bit#(2)     down7();
endinterface
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
    method Action      data0(Bit#(8) v);
    method Action      data1(Bit#(8) v);
    method Action      data2(Bit#(8) v);
    method Action      data3(Bit#(8) v);
    method Action      data4(Bit#(8) v);
    method Action      data5(Bit#(8) v);
    method Action      data6(Bit#(8) v);
    method Action      data7(Bit#(8) v);
    method Action      datak0(Bit#(1) v);
    method Action      datak1(Bit#(1) v);
    method Action      datak2(Bit#(1) v);
    method Action      datak3(Bit#(1) v);
    method Action      datak4(Bit#(1) v);
    method Action      datak5(Bit#(1) v);
    method Action      datak6(Bit#(1) v);
    method Action      datak7(Bit#(1) v);
    method Action      elecidle0(Bit#(1) v);
    method Action      elecidle1(Bit#(1) v);
    method Action      elecidle2(Bit#(1) v);
    method Action      elecidle3(Bit#(1) v);
    method Action      elecidle4(Bit#(1) v);
    method Action      elecidle5(Bit#(1) v);
    method Action      elecidle6(Bit#(1) v);
    method Action      elecidle7(Bit#(1) v);
    method Bit#(1)     polarity0();
    method Bit#(1)     polarity1();
    method Bit#(1)     polarity2();
    method Bit#(1)     polarity3();
    method Bit#(1)     polarity4();
    method Bit#(1)     polarity5();
    method Bit#(1)     polarity6();
    method Bit#(1)     polarity7();
    method Action      status0(Bit#(3) v);
    method Action      status1(Bit#(3) v);
    method Action      status2(Bit#(3) v);
    method Action      status3(Bit#(3) v);
    method Action      status4(Bit#(3) v);
    method Action      status5(Bit#(3) v);
    method Action      status6(Bit#(3) v);
    method Action      status7(Bit#(3) v);
    method Action      valid0(Bit#(1) v);
    method Action      valid1(Bit#(1) v);
    method Action      valid2(Bit#(1) v);
    method Action      valid3(Bit#(1) v);
    method Action      valid4(Bit#(1) v);
    method Action      valid5(Bit#(1) v);
    method Action      valid6(Bit#(1) v);
    method Action      valid7(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapRx_par;
    method Bit#(1)     err();
endinterface
(* always_ready, always_enabled *)
interface PciewrapRx_st;
    method Bit#(8)     bar0();
    method Bit#(16)    be0();
    method Bit#(128)   data0();
    method Bit#(2)     empty0();
    method Bit#(1)     eop0();
    method Bit#(1)     err0();
    method Action      mask0(Bit#(1) v);
    method Action      ready0(Bit#(1) v);
    method Bit#(1)     sop0();
    method Bit#(1)     valid0();
endinterface
(* always_ready, always_enabled *)
interface PciewrapSerdes;
    method Bit#(1)     pll_locked();
endinterface
(* always_ready, always_enabled *)
interface PciewrapSim;
    method Bit#(5)     ltssmstate();
    method Bit#(2)     pipe_rate();
endinterface
(* always_ready, always_enabled *)
interface PciewrapTest;
    method Action      in(Bit#(32) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapTestin;
    method Bit#(1)     zero();
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
    method Bit#(1)     compl0();
    method Bit#(1)     compl1();
    method Bit#(1)     compl2();
    method Bit#(1)     compl3();
    method Bit#(1)     compl4();
    method Bit#(1)     compl5();
    method Bit#(1)     compl6();
    method Bit#(1)     compl7();
    method Bit#(8)     data0();
    method Bit#(8)     data1();
    method Bit#(8)     data2();
    method Bit#(8)     data3();
    method Bit#(8)     data4();
    method Bit#(8)     data5();
    method Bit#(8)     data6();
    method Bit#(8)     data7();
    method Bit#(1)     datak0();
    method Bit#(1)     datak1();
    method Bit#(1)     datak2();
    method Bit#(1)     datak3();
    method Bit#(1)     datak4();
    method Bit#(1)     datak5();
    method Bit#(1)     datak6();
    method Bit#(1)     datak7();
    method Bit#(1)     deemph0();
    method Bit#(1)     deemph1();
    method Bit#(1)     deemph2();
    method Bit#(1)     deemph3();
    method Bit#(1)     deemph4();
    method Bit#(1)     deemph5();
    method Bit#(1)     deemph6();
    method Bit#(1)     deemph7();
    method Bit#(1)     detectrx0();
    method Bit#(1)     detectrx1();
    method Bit#(1)     detectrx2();
    method Bit#(1)     detectrx3();
    method Bit#(1)     detectrx4();
    method Bit#(1)     detectrx5();
    method Bit#(1)     detectrx6();
    method Bit#(1)     detectrx7();
    method Bit#(1)     elecidle0();
    method Bit#(1)     elecidle1();
    method Bit#(1)     elecidle2();
    method Bit#(1)     elecidle3();
    method Bit#(1)     elecidle4();
    method Bit#(1)     elecidle5();
    method Bit#(1)     elecidle6();
    method Bit#(1)     elecidle7();
    method Bit#(3)     margin0();
    method Bit#(3)     margin1();
    method Bit#(3)     margin2();
    method Bit#(3)     margin3();
    method Bit#(3)     margin4();
    method Bit#(3)     margin5();
    method Bit#(3)     margin6();
    method Bit#(3)     margin7();
    method Bit#(1)     swing0();
    method Bit#(1)     swing1();
    method Bit#(1)     swing2();
    method Bit#(1)     swing3();
    method Bit#(1)     swing4();
    method Bit#(1)     swing5();
    method Bit#(1)     swing6();
    method Bit#(1)     swing7();
endinterface
(* always_ready, always_enabled *)
interface PciewrapTx_cred;
    method Bit#(12)     datafccp();
    method Bit#(12)     datafcnp();
    method Bit#(12)     datafcp();
    method Bit#(6)     fchipcons();
    method Bit#(6)     fcinfinite();
    method Bit#(8)     hdrfccp();
    method Bit#(8)     hdrfcnp();
    method Bit#(8)     hdrfcp();
endinterface
(* always_ready, always_enabled *)
interface PciewrapTx_par;
    method Bit#(2)     err();
endinterface
(* always_ready, always_enabled *)
interface PciewrapTx_st;
    method Action      data0(Bit#(128) v);
    method Action      empty0(Bit#(2) v);
    method Action      eop0(Bit#(1) v);
    method Action      err0(Bit#(1) v);
    method Bit#(1)     ready0();
    method Action      sop0(Bit#(1) v);
    method Action      valid0(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PcieS5Wrap;
    interface PciewrapApp     app;
    interface PciewrapCfg_par     cfg_par;
    interface PciewrapCoreclkout     coreclkout;
    interface PciewrapCpl     cpl;
    interface PciewrapCurrent     current;
    interface PciewrapDerr     derr;
    interface PciewrapDl     dl;
    interface PciewrapEidle     eidle;
    interface PciewrapEv128     ev128;
    interface PciewrapEv1     ev1;
    interface PciewrapHotrst     hotrst;
    interface PciewrapHpg     hpg;
    interface PciewrapInt_s     int_s;
    interface PciewrapKo     ko;
    interface PciewrapL2     l2;
    interface PciewrapLane     lane;
    interface PciewrapLtssm     ltssm;
    interface PciewrapPhy     phy;
    interface PciewrapPld     pld;
    interface PciewrapPm     pm;
    interface PciewrapPm_e     pm_e;
    interface PciewrapPme     pme;
    interface PciewrapPower     power;
    interface PciewrapReconfig     reconfig;
    interface PciewrapReset     reset;
    interface PciewrapRx     rx;
    interface PciewrapRx_par     rx_par;
    interface PciewrapRx_st     rx_st;
    interface PciewrapSerdes     serdes;
    interface PciewrapSim     sim;
    interface PciewrapTest     test;
    interface PciewrapTestin     testin;
    interface PciewrapTl     tl;
    interface PciewrapTx_cred     tx_cred;
    interface PciewrapTx     tx;
    interface PciewrapTx_par     tx_par;
    interface PciewrapTx_st     tx_st;
endinterface
import "BVI" altera_pcie_sv_hip_ast_wrapper =
module mkPPS5Wrap#(Clock refclk, Reset npor, Reset pin_perst, Reset refclk_reset)(PcieS5Wrap);
    default_clock clk();
    default_reset rst();
    input_reset npor(npor) = npor;
        input_reset pin_perst(pin_perst) = pin_perst;
    input_clock refclk(refclk) = refclk;
    input_reset refclk_reset() = refclk_reset; /* from clock*/
    interface PciewrapApp     app;
        method app_int_ack int_ack() clocked_by(coreclkout.hip);
        method int_sts(app_int_sts) clocked_by(coreclkout.hip) enable((*inhigh*) EN_app_int_sts);
        method app_msi_ack msi_ack() clocked_by(coreclkout.hip);
        method msi_num(app_msi_num) clocked_by(coreclkout.hip) enable((*inhigh*) EN_app_msi_num);
        method msi_req(app_msi_req) clocked_by(coreclkout.hip) enable((*inhigh*) EN_app_msi_req);
        method msi_tc(app_msi_tc) clocked_by(coreclkout.hip) enable((*inhigh*) EN_app_msi_tc);
    endinterface
    interface PciewrapCfg_par     cfg_par;
        method cfg_par_err err() clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapCoreclkout     coreclkout;
        output_clock hip(coreclkout_hip);
    endinterface
    interface PciewrapCpl     cpl;
        method err(cpl_err) clocked_by(coreclkout.hip) enable((*inhigh*) EN_cpl_err);
        method pending(cpl_pending) clocked_by(coreclkout_hip) enable((*inhigh*) EN_cpl_pending);
    endinterface
    interface PciewrapCurrent     current;
        method currentspeed speed() clocked_by(coreclkout.hip) reset_by(no_reset);
    endinterface
    interface PciewrapDerr     derr;
        method derr_cor_ext_rcv cor_ext_rcv()clocked_by(coreclkout.hip);
        method derr_cor_ext_rpl cor_ext_rpl()clocked_by(coreclkout.hip);
        method derr_rpl rpl() clocked_by(coreclkout.hip) reset_by(no_reset);
    endinterface
    interface PciewrapDl     dl;
        method dlup up() clocked_by(coreclkout.hip) reset_by(no_reset);
        method dlup_exit up_exit() clocked_by(coreclkout.hip) reset_by(no_reset);
    endinterface
    interface PciewrapEidle     eidle;
        method eidleinfersel0 infersel0();
        method eidleinfersel1 infersel1();
        method eidleinfersel2 infersel2();
        method eidleinfersel3 infersel3();
        method eidleinfersel4 infersel4();
        method eidleinfersel5 infersel5();
        method eidleinfersel6 infersel6();
        method eidleinfersel7 infersel7();
    endinterface
    interface PciewrapEv128     ev128;
        method ev128ns ns()clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapEv1     ev1;
        method ev1us us()clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapHotrst     hotrst;
        method hotrst_exit exit() clocked_by(coreclkout.hip) reset_by(no_reset);
    endinterface
    interface PciewrapHpg     hpg;
        method ctrler(hpg_ctrler) enable((*inhigh*) EN_hpg_ctrler);
    endinterface
    interface PciewrapInt_s     int_s;
        method int_status tatus() clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapKo     ko;
        method ko_cpl_spc_data cpl_spc_data()clocked_by(coreclkout.hip);
        method ko_cpl_spc_header cpl_spc_header()clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapL2     l2;
        method l2_exit exit()clocked_by(coreclkout.hip) reset_by (no_reset);
    endinterface
    interface PciewrapLane     lane;
        method lane_act act()clocked_by(coreclkout.hip) reset_by (no_reset);
    endinterface
    interface PciewrapLtssm     ltssm;
        method ltssmstate state() clocked_by(coreclkout.hip) reset_by(no_reset);
    endinterface
    interface PciewrapPhy     phy;
        method status0(phystatus0) enable((*inhigh*) EN_phystatus0);
        method status1(phystatus1) enable((*inhigh*) EN_phystatus1);
        method status2(phystatus2) enable((*inhigh*) EN_phystatus2);
        method status3(phystatus3) enable((*inhigh*) EN_phystatus3);
        method status4(phystatus4) enable((*inhigh*) EN_phystatus4);
        method status5(phystatus5) enable((*inhigh*) EN_phystatus5);
        method status6(phystatus6) enable((*inhigh*) EN_phystatus6);
        method status7(phystatus7) enable((*inhigh*) EN_phystatus7);
    endinterface
    interface PciewrapPld     pld;
        method clk(pld_clk) enable((*inhigh*) EN_pld_clk);
        method pld_clk_inuse clk_inuse() clocked_by(coreclkout.hip);
        method core_ready(pld_core_ready) clocked_by(coreclkout_hip) enable((*inhigh*) EN_pld_core_ready);
    endinterface
    interface PciewrapPm     pm;
        method auxpwr(pm_auxpwr) enable((*inhigh*) EN_pm_auxpwr);
        method data(pm_data) enable((*inhigh*) EN_pm_data);
    endinterface
    interface PciewrapPm_e     pm_e;
        method vent(pm_event) enable((*inhigh*) EN_pm_event);
    endinterface
    interface PciewrapPme     pme;
        method to_cr(pme_to_cr) enable((*inhigh*) EN_pme_to_cr);
        method pme_to_sr to_sr();
    endinterface
    interface PciewrapPower     power;
        method powerdown0 down0();
        method powerdown1 down1();
        method powerdown2 down2();
        method powerdown3 down3();
        method powerdown4 down4();
        method powerdown5 down5();
        method powerdown6 down6();
        method powerdown7 down7();
    endinterface
    interface PciewrapReconfig     reconfig;
        method reconfig_from_xcvr from_xcvr();
        method to_xcvr(reconfig_to_xcvr) enable((*inhigh*) EN_reconfig_to_xcvr);
    endinterface
    interface PciewrapReset     reset;
        output_reset status(reset_status);
    endinterface
    interface PciewrapRx     rx;
        method in0(rx_in0) enable((*inhigh*) EN_rx_in0);
        method in1(rx_in1) enable((*inhigh*) EN_rx_in1);
        method in2(rx_in2) enable((*inhigh*) EN_rx_in2);
        method in3(rx_in3) enable((*inhigh*) EN_rx_in3);
        method in4(rx_in4) enable((*inhigh*) EN_rx_in4);
        method in5(rx_in5) enable((*inhigh*) EN_rx_in5);
        method in6(rx_in6) enable((*inhigh*) EN_rx_in6);
        method in7(rx_in7) enable((*inhigh*) EN_rx_in7);
        method data0(rxdata0) enable((*inhigh*) EN_rxdata0);
        method data1(rxdata1) enable((*inhigh*) EN_rxdata1);
        method data2(rxdata2) enable((*inhigh*) EN_rxdata2);
        method data3(rxdata3) enable((*inhigh*) EN_rxdata3);
        method data4(rxdata4) enable((*inhigh*) EN_rxdata4);
        method data5(rxdata5) enable((*inhigh*) EN_rxdata5);
        method data6(rxdata6) enable((*inhigh*) EN_rxdata6);
        method data7(rxdata7) enable((*inhigh*) EN_rxdata7);
        method datak0(rxdatak0) enable((*inhigh*) EN_rxdatak0);
        method datak1(rxdatak1) enable((*inhigh*) EN_rxdatak1);
        method datak2(rxdatak2) enable((*inhigh*) EN_rxdatak2);
        method datak3(rxdatak3) enable((*inhigh*) EN_rxdatak3);
        method datak4(rxdatak4) enable((*inhigh*) EN_rxdatak4);
        method datak5(rxdatak5) enable((*inhigh*) EN_rxdatak5);
        method datak6(rxdatak6) enable((*inhigh*) EN_rxdatak6);
        method datak7(rxdatak7) enable((*inhigh*) EN_rxdatak7);
        method elecidle0(rxelecidle0) enable((*inhigh*) EN_rxelecidle0);
        method elecidle1(rxelecidle1) enable((*inhigh*) EN_rxelecidle1);
        method elecidle2(rxelecidle2) enable((*inhigh*) EN_rxelecidle2);
        method elecidle3(rxelecidle3) enable((*inhigh*) EN_rxelecidle3);
        method elecidle4(rxelecidle4) enable((*inhigh*) EN_rxelecidle4);
        method elecidle5(rxelecidle5) enable((*inhigh*) EN_rxelecidle5);
        method elecidle6(rxelecidle6) enable((*inhigh*) EN_rxelecidle6);
        method elecidle7(rxelecidle7) enable((*inhigh*) EN_rxelecidle7);
        method rxpolarity0 polarity0();
        method rxpolarity1 polarity1();
        method rxpolarity2 polarity2();
        method rxpolarity3 polarity3();
        method rxpolarity4 polarity4();
        method rxpolarity5 polarity5();
        method rxpolarity6 polarity6();
        method rxpolarity7 polarity7();
        method status0(rxstatus0) enable((*inhigh*) EN_rxstatus0);
        method status1(rxstatus1) enable((*inhigh*) EN_rxstatus1);
        method status2(rxstatus2) enable((*inhigh*) EN_rxstatus2);
        method status3(rxstatus3) enable((*inhigh*) EN_rxstatus3);
        method status4(rxstatus4) enable((*inhigh*) EN_rxstatus4);
        method status5(rxstatus5) enable((*inhigh*) EN_rxstatus5);
        method status6(rxstatus6) enable((*inhigh*) EN_rxstatus6);
        method status7(rxstatus7) enable((*inhigh*) EN_rxstatus7);
        method valid0(rxvalid0) enable((*inhigh*) EN_rxvalid0);
        method valid1(rxvalid1) enable((*inhigh*) EN_rxvalid1);
        method valid2(rxvalid2) enable((*inhigh*) EN_rxvalid2);
        method valid3(rxvalid3) enable((*inhigh*) EN_rxvalid3);
        method valid4(rxvalid4) enable((*inhigh*) EN_rxvalid4);
        method valid5(rxvalid5) enable((*inhigh*) EN_rxvalid5);
        method valid6(rxvalid6) enable((*inhigh*) EN_rxvalid6);
        method valid7(rxvalid7) enable((*inhigh*) EN_rxvalid7);
    endinterface
    interface PciewrapRx_par     rx_par;
        method rx_par_err err()clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapRx_st     rx_st;
        method rx_st_bar   bar0() clocked_by(coreclkout.hip);
        method rx_st_be    be0() clocked_by(coreclkout.hip);
        method rx_st_data  data0() clocked_by(coreclkout.hip);
        method rx_st_empty empty0() clocked_by(coreclkout.hip);
        method rx_st_eop   eop0() clocked_by(coreclkout.hip);
        method rx_st_err   err0() clocked_by(coreclkout.hip);
        method mask0(rx_st_mask) clocked_by(coreclkout.hip) enable((*inhigh*) EN_rx_st_mask);
        method ready0(rx_st_ready) clocked_by(coreclkout.hip) enable((*inhigh*) EN_rx_st_ready);
        method rx_st_sop   sop0() clocked_by(coreclkout.hip);
        method rx_st_valid valid0() clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapSerdes     serdes;
        method serdes_pll_locked pll_locked()clocked_by(coreclkout_hip);
    endinterface
    interface PciewrapSim     sim;
        method sim_ltssmstate ltssmstate();
        method sim_pipe_rate pipe_rate();
    endinterface
    interface PciewrapTest     test;
        method in(test_in) enable((*inhigh*) EN_test_in);
    endinterface
    interface PciewrapTestin     testin;
        method testin_zero zero();
    endinterface
    interface PciewrapTl     tl;
        method tl_cfg_add cfg_add() clocked_by(coreclkout_hip) reset_by (no_reset);
        method tl_cfg_ctl cfg_ctl() clocked_by(coreclkout_hip) reset_by (no_reset);
        method tl_cfg_sts cfg_sts() clocked_by(coreclkout_hip) reset_by (no_reset);
    endinterface
    interface PciewrapTx_cred     tx_cred;
        method tx_cred_datafccp datafccp()clocked_by(coreclkout.hip);
        method tx_cred_datafcnp datafcnp()clocked_by(coreclkout.hip);
        method tx_cred_datafcp datafcp()clocked_by(coreclkout.hip);
        method tx_cred_fchipcons fchipcons()clocked_by(coreclkout.hip);
        method tx_cred_fcinfinite fcinfinite()clocked_by(coreclkout.hip);
        method tx_cred_hdrfccp hdrfccp()clocked_by(coreclkout.hip);
        method tx_cred_hdrfcnp hdrfcnp()clocked_by(coreclkout.hip);
        method tx_cred_hdrfcp hdrfcp()clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapTx     tx;
        method tx_out0 out0();
        method tx_out1 out1();
        method tx_out2 out2();
        method tx_out3 out3();
        method tx_out4 out4();
        method tx_out5 out5();
        method tx_out6 out6();
        method tx_out7 out7();
        method txcompl0 compl0();
        method txcompl1 compl1();
        method txcompl2 compl2();
        method txcompl3 compl3();
        method txcompl4 compl4();
        method txcompl5 compl5();
        method txcompl6 compl6();
        method txcompl7 compl7();
        method txdata0 data0();
        method txdata1 data1();
        method txdata2 data2();
        method txdata3 data3();
        method txdata4 data4();
        method txdata5 data5();
        method txdata6 data6();
        method txdata7 data7();
        method txdatak0 datak0();
        method txdatak1 datak1();
        method txdatak2 datak2();
        method txdatak3 datak3();
        method txdatak4 datak4();
        method txdatak5 datak5();
        method txdatak6 datak6();
        method txdatak7 datak7();
        method txdeemph0 deemph0();
        method txdeemph1 deemph1();
        method txdeemph2 deemph2();
        method txdeemph3 deemph3();
        method txdeemph4 deemph4();
        method txdeemph5 deemph5();
        method txdeemph6 deemph6();
        method txdeemph7 deemph7();
        method txdetectrx0 detectrx0();
        method txdetectrx1 detectrx1();
        method txdetectrx2 detectrx2();
        method txdetectrx3 detectrx3();
        method txdetectrx4 detectrx4();
        method txdetectrx5 detectrx5();
        method txdetectrx6 detectrx6();
        method txdetectrx7 detectrx7();
        method txelecidle0 elecidle0();
        method txelecidle1 elecidle1();
        method txelecidle2 elecidle2();
        method txelecidle3 elecidle3();
        method txelecidle4 elecidle4();
        method txelecidle5 elecidle5();
        method txelecidle6 elecidle6();
        method txelecidle7 elecidle7();
        method txmargin0 margin0();
        method txmargin1 margin1();
        method txmargin2 margin2();
        method txmargin3 margin3();
        method txmargin4 margin4();
        method txmargin5 margin5();
        method txmargin6 margin6();
        method txmargin7 margin7();
        method txswing0 swing0();
        method txswing1 swing1();
        method txswing2 swing2();
        method txswing3 swing3();
        method txswing4 swing4();
        method txswing5 swing5();
        method txswing6 swing6();
        method txswing7 swing7();
    endinterface
    interface PciewrapTx_par     tx_par;
        method tx_par_err err()clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapTx_st     tx_st;
        method data0(tx_st_data)    clocked_by(coreclkout.hip) enable((*inhigh*) EN_tx_st_data);
        method empty0(tx_st_empty)  clocked_by(coreclkout.hip) enable((*inhigh*) EN_tx_st_empty);
        method eop0(tx_st_eop)      clocked_by(coreclkout.hip) enable((*inhigh*) EN_tx_st_eop);
        method err0(tx_st_err)      clocked_by(coreclkout_hip) enable((*inhigh*) EN_tx_st_err);
        method tx_st_ready ready0() clocked_by(coreclkout.hip);
        method sop0(tx_st_sop)      clocked_by(coreclkout.hip) enable((*inhigh*) EN_tx_st_sop);
        method valid0(tx_st_valid)  clocked_by(coreclkout.hip) enable((*inhigh*) EN_tx_st_valid);
    endinterface
    schedule (app.int_ack, app.int_sts, app.msi_ack, app.msi_num, app.msi_req, app.msi_tc, cfg_par.err, cpl.err, cpl.pending, current.speed, derr.cor_ext_rcv, derr.cor_ext_rpl, derr.rpl, dl.up, dl.up_exit, eidle.infersel0, eidle.infersel1, eidle.infersel2, eidle.infersel3, eidle.infersel4, eidle.infersel5, eidle.infersel6, eidle.infersel7, ev128.ns, ev1.us, hotrst.exit, hpg.ctrler, int_s.tatus, ko.cpl_spc_data, ko.cpl_spc_header, l2.exit, lane.act, ltssm.state, phy.status0, phy.status1, phy.status2, phy.status3, phy.status4, phy.status5, phy.status6, phy.status7, pld.clk, pld.clk_inuse, pld.core_ready, pm.auxpwr, pm.data, pm_e.vent, pme.to_cr, pme.to_sr, power.down0, power.down1, power.down2, power.down3, power.down4, power.down5, power.down6, power.down7, reconfig.from_xcvr, reconfig.to_xcvr, rx.in0, rx.in1, rx.in2, rx.in3, rx.in4, rx.in5, rx.in6, rx.in7, rx_par.err, rx_st.bar0, rx_st.be0, rx_st.data0, rx_st.empty0, rx_st.eop0, rx_st.err0, rx_st.mask0, rx_st.ready0, rx_st.sop0, rx_st.valid0, rx.data0, rx.data1, rx.data2, rx.data3, rx.data4, rx.data5, rx.data6, rx.data7, rx.datak0, rx.datak1, rx.datak2, rx.datak3, rx.datak4, rx.datak5, rx.datak6, rx.datak7, rx.elecidle0, rx.elecidle1, rx.elecidle2, rx.elecidle3, rx.elecidle4, rx.elecidle5, rx.elecidle6, rx.elecidle7, rx.polarity0, rx.polarity1, rx.polarity2, rx.polarity3, rx.polarity4, rx.polarity5, rx.polarity6, rx.polarity7, rx.status0, rx.status1, rx.status2, rx.status3, rx.status4, rx.status5, rx.status6, rx.status7, rx.valid0, rx.valid1, rx.valid2, rx.valid3, rx.valid4, rx.valid5, rx.valid6, rx.valid7, serdes.pll_locked, sim.ltssmstate, sim.pipe_rate, test.in, testin.zero, tl.cfg_add, tl.cfg_ctl, tl.cfg_sts, tx_cred.datafccp, tx_cred.datafcnp, tx_cred.datafcp, tx_cred.fchipcons, tx_cred.fcinfinite, tx_cred.hdrfccp, tx_cred.hdrfcnp, tx_cred.hdrfcp, tx.out0, tx.out1, tx.out2, tx.out3, tx.out4, tx.out5, tx.out6, tx.out7, tx_par.err, tx_st.data0, tx_st.empty0, tx_st.eop0, tx_st.err0, tx_st.ready0, tx_st.sop0, tx_st.valid0, tx.compl0, tx.compl1, tx.compl2, tx.compl3, tx.compl4, tx.compl5, tx.compl6, tx.compl7, tx.data0, tx.data1, tx.data2, tx.data3, tx.data4, tx.data5, tx.data6, tx.data7, tx.datak0, tx.datak1, tx.datak2, tx.datak3, tx.datak4, tx.datak5, tx.datak6, tx.datak7, tx.deemph0, tx.deemph1, tx.deemph2, tx.deemph3, tx.deemph4, tx.deemph5, tx.deemph6, tx.deemph7, tx.detectrx0, tx.detectrx1, tx.detectrx2, tx.detectrx3, tx.detectrx4, tx.detectrx5, tx.detectrx6, tx.detectrx7, tx.elecidle0, tx.elecidle1, tx.elecidle2, tx.elecidle3, tx.elecidle4, tx.elecidle5, tx.elecidle6, tx.elecidle7, tx.margin0, tx.margin1, tx.margin2, tx.margin3, tx.margin4, tx.margin5, tx.margin6, tx.margin7, tx.swing0, tx.swing1, tx.swing2, tx.swing3, tx.swing4, tx.swing5, tx.swing6, tx.swing7) CF (app.int_ack, app.int_sts, app.msi_ack, app.msi_num, app.msi_req, app.msi_tc, cfg_par.err, cpl.err, cpl.pending, current.speed, derr.cor_ext_rcv, derr.cor_ext_rpl, derr.rpl, dl.up, dl.up_exit, eidle.infersel0, eidle.infersel1, eidle.infersel2, eidle.infersel3, eidle.infersel4, eidle.infersel5, eidle.infersel6, eidle.infersel7, ev128.ns, ev1.us, hotrst.exit, hpg.ctrler, int_s.tatus, ko.cpl_spc_data, ko.cpl_spc_header, l2.exit, lane.act, ltssm.state, phy.status0, phy.status1, phy.status2, phy.status3, phy.status4, phy.status5, phy.status6, phy.status7, pld.clk, pld.clk_inuse, pld.core_ready, pm.auxpwr, pm.data, pm_e.vent, pme.to_cr, pme.to_sr, power.down0, power.down1, power.down2, power.down3, power.down4, power.down5, power.down6, power.down7, reconfig.from_xcvr, reconfig.to_xcvr, rx.in0, rx.in1, rx.in2, rx.in3, rx.in4, rx.in5, rx.in6, rx.in7, rx_par.err, rx_st.bar0, rx_st.be0, rx_st.data0, rx_st.empty0, rx_st.eop0, rx_st.err0, rx_st.mask0, rx_st.ready0, rx_st.sop0, rx_st.valid0, rx.data0, rx.data1, rx.data2, rx.data3, rx.data4, rx.data5, rx.data6, rx.data7, rx.datak0, rx.datak1, rx.datak2, rx.datak3, rx.datak4, rx.datak5, rx.datak6, rx.datak7, rx.elecidle0, rx.elecidle1, rx.elecidle2, rx.elecidle3, rx.elecidle4, rx.elecidle5, rx.elecidle6, rx.elecidle7, rx.polarity0, rx.polarity1, rx.polarity2, rx.polarity3, rx.polarity4, rx.polarity5, rx.polarity6, rx.polarity7, rx.status0, rx.status1, rx.status2, rx.status3, rx.status4, rx.status5, rx.status6, rx.status7, rx.valid0, rx.valid1, rx.valid2, rx.valid3, rx.valid4, rx.valid5, rx.valid6, rx.valid7, serdes.pll_locked, sim.ltssmstate, sim.pipe_rate, test.in, testin.zero, tl.cfg_add, tl.cfg_ctl, tl.cfg_sts, tx_cred.datafccp, tx_cred.datafcnp, tx_cred.datafcp, tx_cred.fchipcons, tx_cred.fcinfinite, tx_cred.hdrfccp, tx_cred.hdrfcnp, tx_cred.hdrfcp, tx.out0, tx.out1, tx.out2, tx.out3, tx.out4, tx.out5, tx.out6, tx.out7, tx_par.err, tx_st.data0, tx_st.empty0, tx_st.eop0, tx_st.err0, tx_st.ready0, tx_st.sop0, tx_st.valid0, tx.compl0, tx.compl1, tx.compl2, tx.compl3, tx.compl4, tx.compl5, tx.compl6, tx.compl7, tx.data0, tx.data1, tx.data2, tx.data3, tx.data4, tx.data5, tx.data6, tx.data7, tx.datak0, tx.datak1, tx.datak2, tx.datak3, tx.datak4, tx.datak5, tx.datak6, tx.datak7, tx.deemph0, tx.deemph1, tx.deemph2, tx.deemph3, tx.deemph4, tx.deemph5, tx.deemph6, tx.deemph7, tx.detectrx0, tx.detectrx1, tx.detectrx2, tx.detectrx3, tx.detectrx4, tx.detectrx5, tx.detectrx6, tx.detectrx7, tx.elecidle0, tx.elecidle1, tx.elecidle2, tx.elecidle3, tx.elecidle4, tx.elecidle5, tx.elecidle6, tx.elecidle7, tx.margin0, tx.margin1, tx.margin2, tx.margin3, tx.margin4, tx.margin5, tx.margin6, tx.margin7, tx.swing0, tx.swing1, tx.swing2, tx.swing3, tx.swing4, tx.swing5, tx.swing6, tx.swing7);
endmodule
