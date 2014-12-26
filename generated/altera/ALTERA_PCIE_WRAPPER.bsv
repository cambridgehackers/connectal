
/*
   ./importbvi.py
   -o
   ALTERA_PCIE_WRAPPER.bsv
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
   pld_clk
   -c
   coreclkout_hip
   -f
   serdes
   -f
   pld_clk
   -f
   pld_cor
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
   in
   -f
   aer
   -f
   pex
   -f
   serr
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
   tx_cred
   -f
   tx_par
   -f
   rx_par
   -f
   cfg_par
   -f
   tx
   -f
   rx
   -f
   eidle
   -f
   power
   -f
   phy
   -f
   sim
   -f
   test_in
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
interface PciewrapIn;
    method Bit#(4)     t_status();
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
interface PciewrapLmi;
    method Bit#(1)     ack();
    method Action      addr(Bit#(12) v);
    method Action      din(Bit#(32) v);
    method Bit#(32)     dout();
    method Action      rden(Bit#(1) v);
    method Action      wren(Bit#(1) v);
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
(* always_ready, always_enabled *)
interface PciewrapPld_clk;
    method Bit#(1)     inuse();
endinterface
(* always_ready, always_enabled *)
interface PciewrapPld_cor;
    method Action      e_ready(Bit#(1) v);
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
    method Bit#(8)     st_bar();
    method Bit#(128)     st_data();
    method Bit#(2)     st_empty();
    method Bit#(1)     st_eop();
    method Bit#(1)     st_err();
    method Action      st_mask(Bit#(1) v);
    method Action      st_ready(Bit#(1) v);
    method Bit#(1)     st_sop();
    method Bit#(1)     st_valid();
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
interface PciewrapSerdes;
    method Bit#(1)     pll_locked();
endinterface
(* always_ready, always_enabled *)
interface PciewrapSim;
    method Bit#(5)     ltssmstate();
    method Action      pipe_pclk_in(Bit#(1) v);
    method Bit#(2)     pipe_rate();
    method Action      u_mode_pipe(Bit#(1) v);
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
    method Action      st_data(Bit#(128) v);
    method Action      st_empty(Bit#(2) v);
    method Action      st_eop(Bit#(1) v);
    method Action      st_err(Bit#(1) v);
    method Bit#(1)     st_ready();
    method Action      st_sop(Bit#(1) v);
    method Action      st_valid(Bit#(1) v);
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
interface PcieWrap;
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
    interface PciewrapIn     in;
    interface PciewrapKo     ko;
    interface PciewrapL2     l2;
    interface PciewrapLane     lane;
    interface PciewrapLmi     lmi;
    interface PciewrapLtssm     ltssm;
    interface PciewrapPhy     phy;
    interface PciewrapPld_clk     pld_clk;
    interface PciewrapPld_cor     pld_cor;
    interface PciewrapPm     pm;
    interface PciewrapPm_e     pm_e;
    interface PciewrapPme     pme;
    interface PciewrapPower     power;
    interface PciewrapReconfig     reconfig;
    interface PciewrapReset     reset;
    interface PciewrapRx     rx;
    interface PciewrapRx_par     rx_par;
    interface PciewrapSerdes     serdes;
    interface PciewrapSim     sim;
    interface PciewrapTest     test;
    interface PciewrapTestin     testin;
    interface PciewrapTl     tl;
    interface PciewrapTx_cred     tx_cred;
    interface PciewrapTx     tx;
    interface PciewrapTx_par     tx_par;
endinterface
import "BVI" altera_pcie_sv_hip_ast =
module mkPcieWrap#(Clock pld_clk, Clock refclk, Reset npor, Reset pin_perst, Reset pld_clk_reset, Reset refclk_reset)(PcieWrap);
    default_clock clk();
    default_reset rst();
    input_reset npor(npor) = npor;
        input_reset pin_perst(pin_perst) = pin_perst;
        input_clock pld_clk(pld_clk) = pld_clk;
        input_reset pld_clk_reset() = pld_clk_reset; /* from clock*/
    input_clock refclk(refclk) = refclk;
    input_reset refclk_reset() = refclk_reset; /* from clock*/
    interface PciewrapApp     app;
        method app_int_ack int_ack();
        method int_sts(app_int_sts) enable((*inhigh*) EN_app_int_sts);
        method app_msi_ack msi_ack();
        method msi_num(app_msi_num) enable((*inhigh*) EN_app_msi_num);
        method msi_req(app_msi_req) enable((*inhigh*) EN_app_msi_req);
        method msi_tc(app_msi_tc) enable((*inhigh*) EN_app_msi_tc);
    endinterface
    interface PciewrapCfg_par     cfg_par;
        method cfg_parerr err();
    endinterface
    interface PciewrapCoreclkout     coreclkout;
        output_clock hip(coreclkout_hip);
    endinterface
    interface PciewrapCpl     cpl;
        method err(cplerr) enable((*inhigh*) EN_cplerr);
        method pending(cplpending) enable((*inhigh*) EN_cplpending);
    endinterface
    interface PciewrapCurrent     current;
        method currentspeed speed();
    endinterface
    interface PciewrapDerr     derr;
        method derrcor_ext_rcv cor_ext_rcv();
        method derrcor_ext_rpl cor_ext_rpl();
        method derrrpl rpl();
    endinterface
    interface PciewrapDl     dl;
        method dlup up();
        method dlup_exit up_exit();
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
        method ev128ns ns();
    endinterface
    interface PciewrapEv1     ev1;
        method ev1us us();
    endinterface
    interface PciewrapHotrst     hotrst;
        method hotrstexit exit();
    endinterface
    interface PciewrapHpg     hpg;
        method ctrler(hpg_ctrler) enable((*inhigh*) EN_hpg_ctrler);
    endinterface
    interface PciewrapIn     in;
        method int_status t_status();
    endinterface
    interface PciewrapKo     ko;
        method ko_cpl_spc_data cpl_spc_data();
        method ko_cpl_spc_header cpl_spc_header();
    endinterface
    interface PciewrapL2     l2;
        method l2exit exit();
    endinterface
    interface PciewrapLane     lane;
        method laneact act();
    endinterface
    interface PciewrapLmi     lmi;
        method lmi_ack ack();
        method addr(lmi_addr) enable((*inhigh*) EN_lmi_addr);
        method din(lmi_din) enable((*inhigh*) EN_lmi_din);
        method lmi_dout dout();
        method rden(lmi_rden) enable((*inhigh*) EN_lmi_rden);
        method wren(lmi_wren) enable((*inhigh*) EN_lmi_wren);
    endinterface
    interface PciewrapLtssm     ltssm;
        method ltssmstate state();
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
    interface PciewrapPld_clk     pld_clk;
        method pld_clkinuse inuse();
    endinterface
    interface PciewrapPld_cor     pld_cor;
        method e_ready(pld_core_ready) enable((*inhigh*) EN_pld_core_ready);
    endinterface
    interface PciewrapPm     pm;
        method auxpwr(pmauxpwr) enable((*inhigh*) EN_pmauxpwr);
        method data(pmdata) enable((*inhigh*) EN_pmdata);
    endinterface
    interface PciewrapPm_e     pm_e;
        method vent(pm_event) enable((*inhigh*) EN_pm_event);
    endinterface
    interface PciewrapPme     pme;
        method to_cr(pmeto_cr) enable((*inhigh*) EN_pmeto_cr);
        method pmeto_sr to_sr();
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
        method reconfigfrom_xcvr from_xcvr();
        method to_xcvr(reconfigto_xcvr) enable((*inhigh*) EN_reconfigto_xcvr);
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
        method rxst_bar st_bar();
        method rxst_data st_data();
        method rxst_empty st_empty();
        method rxst_eop st_eop();
        method rxst_err st_err();
        method st_mask(rxst_mask) enable((*inhigh*) EN_rxst_mask);
        method st_ready(rxst_ready) enable((*inhigh*) EN_rxst_ready);
        method rxst_sop st_sop();
        method rxst_valid st_valid();
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
        method rx_parerr err();
    endinterface
    interface PciewrapSerdes     serdes;
        method serdespll_locked pll_locked();
    endinterface
    interface PciewrapSim     sim;
        method simltssmstate ltssmstate();
        method pipe_pclk_in(simpipe_pclk_in) enable((*inhigh*) EN_simpipe_pclk_in);
        method simpipe_rate pipe_rate();
        method u_mode_pipe(simu_mode_pipe) enable((*inhigh*) EN_simu_mode_pipe);
    endinterface
    interface PciewrapTest     test;
        method in(test_in) enable((*inhigh*) EN_test_in);
    endinterface
    interface PciewrapTestin     testin;
        method testin_zero zero();
    endinterface
    interface PciewrapTl     tl;
        method tlcfg_add cfg_add();
        method tlcfg_ctl cfg_ctl();
        method tlcfg_sts cfg_sts();
    endinterface
    interface PciewrapTx_cred     tx_cred;
        method tx_creddatafccp datafccp();
        method tx_creddatafcnp datafcnp();
        method tx_creddatafcp datafcp();
        method tx_credfchipcons fchipcons();
        method tx_credfcinfinite fcinfinite();
        method tx_credhdrfccp hdrfccp();
        method tx_credhdrfcnp hdrfcnp();
        method tx_credhdrfcp hdrfcp();
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
        method st_data(txst_data) enable((*inhigh*) EN_txst_data);
        method st_empty(txst_empty) enable((*inhigh*) EN_txst_empty);
        method st_eop(txst_eop) enable((*inhigh*) EN_txst_eop);
        method st_err(txst_err) enable((*inhigh*) EN_txst_err);
        method txst_ready st_ready();
        method st_sop(txst_sop) enable((*inhigh*) EN_txst_sop);
        method st_valid(txst_valid) enable((*inhigh*) EN_txst_valid);
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
        method tx_parerr err();
    endinterface
    schedule (app.int_ack, app.int_sts, app.msi_ack, app.msi_num, app.msi_req, app.msi_tc, cfg_par.err, cpl.err, cpl.pending, current.speed, derr.cor_ext_rcv, derr.cor_ext_rpl, derr.rpl, dl.up, dl.up_exit, eidle.infersel0, eidle.infersel1, eidle.infersel2, eidle.infersel3, eidle.infersel4, eidle.infersel5, eidle.infersel6, eidle.infersel7, ev128.ns, ev1.us, hotrst.exit, hpg.ctrler, in.t_status, ko.cpl_spc_data, ko.cpl_spc_header, l2.exit, lane.act, lmi.ack, lmi.addr, lmi.din, lmi.dout, lmi.rden, lmi.wren, ltssm.state, phy.status0, phy.status1, phy.status2, phy.status3, phy.status4, phy.status5, phy.status6, phy.status7, pld_clk.inuse, pld_cor.e_ready, pm.auxpwr, pm.data, pm_e.vent, pme.to_cr, pme.to_sr, power.down0, power.down1, power.down2, power.down3, power.down4, power.down5, power.down6, power.down7, reconfig.from_xcvr, reconfig.to_xcvr, rx.in0, rx.in1, rx.in2, rx.in3, rx.in4, rx.in5, rx.in6, rx.in7, rx.st_bar, rx.st_data, rx.st_empty, rx.st_eop, rx.st_err, rx.st_mask, rx.st_ready, rx.st_sop, rx.st_valid, rx.data0, rx.data1, rx.data2, rx.data3, rx.data4, rx.data5, rx.data6, rx.data7, rx.datak0, rx.datak1, rx.datak2, rx.datak3, rx.datak4, rx.datak5, rx.datak6, rx.datak7, rx.elecidle0, rx.elecidle1, rx.elecidle2, rx.elecidle3, rx.elecidle4, rx.elecidle5, rx.elecidle6, rx.elecidle7, rx.polarity0, rx.polarity1, rx.polarity2, rx.polarity3, rx.polarity4, rx.polarity5, rx.polarity6, rx.polarity7, rx.status0, rx.status1, rx.status2, rx.status3, rx.status4, rx.status5, rx.status6, rx.status7, rx.valid0, rx.valid1, rx.valid2, rx.valid3, rx.valid4, rx.valid5, rx.valid6, rx.valid7, rx_par.err, serdes.pll_locked, sim.ltssmstate, sim.pipe_pclk_in, sim.pipe_rate, sim.u_mode_pipe, test.in, testin.zero, tl.cfg_add, tl.cfg_ctl, tl.cfg_sts, tx_cred.datafccp, tx_cred.datafcnp, tx_cred.datafcp, tx_cred.fchipcons, tx_cred.fcinfinite, tx_cred.hdrfccp, tx_cred.hdrfcnp, tx_cred.hdrfcp, tx.out0, tx.out1, tx.out2, tx.out3, tx.out4, tx.out5, tx.out6, tx.out7, tx.st_data, tx.st_empty, tx.st_eop, tx.st_err, tx.st_ready, tx.st_sop, tx.st_valid, tx.compl0, tx.compl1, tx.compl2, tx.compl3, tx.compl4, tx.compl5, tx.compl6, tx.compl7, tx.data0, tx.data1, tx.data2, tx.data3, tx.data4, tx.data5, tx.data6, tx.data7, tx.datak0, tx.datak1, tx.datak2, tx.datak3, tx.datak4, tx.datak5, tx.datak6, tx.datak7, tx.deemph0, tx.deemph1, tx.deemph2, tx.deemph3, tx.deemph4, tx.deemph5, tx.deemph6, tx.deemph7, tx.detectrx0, tx.detectrx1, tx.detectrx2, tx.detectrx3, tx.detectrx4, tx.detectrx5, tx.detectrx6, tx.detectrx7, tx.elecidle0, tx.elecidle1, tx.elecidle2, tx.elecidle3, tx.elecidle4, tx.elecidle5, tx.elecidle6, tx.elecidle7, tx.margin0, tx.margin1, tx.margin2, tx.margin3, tx.margin4, tx.margin5, tx.margin6, tx.margin7, tx.swing0, tx.swing1, tx.swing2, tx.swing3, tx.swing4, tx.swing5, tx.swing6, tx.swing7, tx_par.err) CF (app.int_ack, app.int_sts, app.msi_ack, app.msi_num, app.msi_req, app.msi_tc, cfg_par.err, cpl.err, cpl.pending, current.speed, derr.cor_ext_rcv, derr.cor_ext_rpl, derr.rpl, dl.up, dl.up_exit, eidle.infersel0, eidle.infersel1, eidle.infersel2, eidle.infersel3, eidle.infersel4, eidle.infersel5, eidle.infersel6, eidle.infersel7, ev128.ns, ev1.us, hotrst.exit, hpg.ctrler, in.t_status, ko.cpl_spc_data, ko.cpl_spc_header, l2.exit, lane.act, lmi.ack, lmi.addr, lmi.din, lmi.dout, lmi.rden, lmi.wren, ltssm.state, phy.status0, phy.status1, phy.status2, phy.status3, phy.status4, phy.status5, phy.status6, phy.status7, pld_clk.inuse, pld_cor.e_ready, pm.auxpwr, pm.data, pm_e.vent, pme.to_cr, pme.to_sr, power.down0, power.down1, power.down2, power.down3, power.down4, power.down5, power.down6, power.down7, reconfig.from_xcvr, reconfig.to_xcvr, rx.in0, rx.in1, rx.in2, rx.in3, rx.in4, rx.in5, rx.in6, rx.in7, rx.st_bar, rx.st_data, rx.st_empty, rx.st_eop, rx.st_err, rx.st_mask, rx.st_ready, rx.st_sop, rx.st_valid, rx.data0, rx.data1, rx.data2, rx.data3, rx.data4, rx.data5, rx.data6, rx.data7, rx.datak0, rx.datak1, rx.datak2, rx.datak3, rx.datak4, rx.datak5, rx.datak6, rx.datak7, rx.elecidle0, rx.elecidle1, rx.elecidle2, rx.elecidle3, rx.elecidle4, rx.elecidle5, rx.elecidle6, rx.elecidle7, rx.polarity0, rx.polarity1, rx.polarity2, rx.polarity3, rx.polarity4, rx.polarity5, rx.polarity6, rx.polarity7, rx.status0, rx.status1, rx.status2, rx.status3, rx.status4, rx.status5, rx.status6, rx.status7, rx.valid0, rx.valid1, rx.valid2, rx.valid3, rx.valid4, rx.valid5, rx.valid6, rx.valid7, rx_par.err, serdes.pll_locked, sim.ltssmstate, sim.pipe_pclk_in, sim.pipe_rate, sim.u_mode_pipe, test.in, testin.zero, tl.cfg_add, tl.cfg_ctl, tl.cfg_sts, tx_cred.datafccp, tx_cred.datafcnp, tx_cred.datafcp, tx_cred.fchipcons, tx_cred.fcinfinite, tx_cred.hdrfccp, tx_cred.hdrfcnp, tx_cred.hdrfcp, tx.out0, tx.out1, tx.out2, tx.out3, tx.out4, tx.out5, tx.out6, tx.out7, tx.st_data, tx.st_empty, tx.st_eop, tx.st_err, tx.st_ready, tx.st_sop, tx.st_valid, tx.compl0, tx.compl1, tx.compl2, tx.compl3, tx.compl4, tx.compl5, tx.compl6, tx.compl7, tx.data0, tx.data1, tx.data2, tx.data3, tx.data4, tx.data5, tx.data6, tx.data7, tx.datak0, tx.datak1, tx.datak2, tx.datak3, tx.datak4, tx.datak5, tx.datak6, tx.datak7, tx.deemph0, tx.deemph1, tx.deemph2, tx.deemph3, tx.deemph4, tx.deemph5, tx.deemph6, tx.deemph7, tx.detectrx0, tx.detectrx1, tx.detectrx2, tx.detectrx3, tx.detectrx4, tx.detectrx5, tx.detectrx6, tx.detectrx7, tx.elecidle0, tx.elecidle1, tx.elecidle2, tx.elecidle3, tx.elecidle4, tx.elecidle5, tx.elecidle6, tx.elecidle7, tx.margin0, tx.margin1, tx.margin2, tx.margin3, tx.margin4, tx.margin5, tx.margin6, tx.margin7, tx.swing0, tx.swing1, tx.swing2, tx.swing3, tx.swing4, tx.swing5, tx.swing6, tx.swing7, tx_par.err);
endmodule
