
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
endinterface
(* always_ready, always_enabled *)
interface PciewrapRx_par;
    method Bit#(1)     err();
endinterface
(* always_ready, always_enabled *)
interface PciewrapRx_s;
    method Bit#(8)     t_bar();
    method Bit#(16)     t_be();
    method Bit#(128)     t_data();
    method Bit#(2)     t_empty();
    method Bit#(1)     t_eop();
    method Bit#(1)     t_err();
    method Action      t_mask(Bit#(1) v);
    method Action      t_ready(Bit#(1) v);
    method Bit#(1)     t_sop();
    method Bit#(1)     t_valid();
endinterface
(* always_ready, always_enabled *)
interface PciewrapRxd;
    method Action      ata0(Bit#(8) v);
    method Action      ata1(Bit#(8) v);
    method Action      ata2(Bit#(8) v);
    method Action      ata3(Bit#(8) v);
    method Action      ata4(Bit#(8) v);
    method Action      ata5(Bit#(8) v);
    method Action      ata6(Bit#(8) v);
    method Action      ata7(Bit#(8) v);
    method Action      atak0(Bit#(1) v);
    method Action      atak1(Bit#(1) v);
    method Action      atak2(Bit#(1) v);
    method Action      atak3(Bit#(1) v);
    method Action      atak4(Bit#(1) v);
    method Action      atak5(Bit#(1) v);
    method Action      atak6(Bit#(1) v);
    method Action      atak7(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapRxe;
    method Action      lecidle0(Bit#(1) v);
    method Action      lecidle1(Bit#(1) v);
    method Action      lecidle2(Bit#(1) v);
    method Action      lecidle3(Bit#(1) v);
    method Action      lecidle4(Bit#(1) v);
    method Action      lecidle5(Bit#(1) v);
    method Action      lecidle6(Bit#(1) v);
    method Action      lecidle7(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapRxp;
    method Bit#(1)     olarity0();
    method Bit#(1)     olarity1();
    method Bit#(1)     olarity2();
    method Bit#(1)     olarity3();
    method Bit#(1)     olarity4();
    method Bit#(1)     olarity5();
    method Bit#(1)     olarity6();
    method Bit#(1)     olarity7();
endinterface
(* always_ready, always_enabled *)
interface PciewrapRxs;
    method Action      tatus0(Bit#(3) v);
    method Action      tatus1(Bit#(3) v);
    method Action      tatus2(Bit#(3) v);
    method Action      tatus3(Bit#(3) v);
    method Action      tatus4(Bit#(3) v);
    method Action      tatus5(Bit#(3) v);
    method Action      tatus6(Bit#(3) v);
    method Action      tatus7(Bit#(3) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapRxv;
    method Action      alid0(Bit#(1) v);
    method Action      alid1(Bit#(1) v);
    method Action      alid2(Bit#(1) v);
    method Action      alid3(Bit#(1) v);
    method Action      alid4(Bit#(1) v);
    method Action      alid5(Bit#(1) v);
    method Action      alid6(Bit#(1) v);
    method Action      alid7(Bit#(1) v);
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
endinterface
(* always_ready, always_enabled *)
interface PciewrapSimu;
    method Action      mode_pipe(Bit#(1) v);
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
interface PciewrapTx_s;
    method Action      t_data(Bit#(128) v);
    method Action      t_empty(Bit#(2) v);
    method Action      t_eop(Bit#(1) v);
    method Action      t_err(Bit#(1) v);
    method Bit#(1)     t_ready();
    method Action      t_sop(Bit#(1) v);
    method Action      t_valid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapTxc;
    method Bit#(1)     ompl0();
    method Bit#(1)     ompl1();
    method Bit#(1)     ompl2();
    method Bit#(1)     ompl3();
    method Bit#(1)     ompl4();
    method Bit#(1)     ompl5();
    method Bit#(1)     ompl6();
    method Bit#(1)     ompl7();
endinterface
(* always_ready, always_enabled *)
interface PciewrapTxd;
    method Bit#(8)     ata0();
    method Bit#(8)     ata1();
    method Bit#(8)     ata2();
    method Bit#(8)     ata3();
    method Bit#(8)     ata4();
    method Bit#(8)     ata5();
    method Bit#(8)     ata6();
    method Bit#(8)     ata7();
    method Bit#(1)     atak0();
    method Bit#(1)     atak1();
    method Bit#(1)     atak2();
    method Bit#(1)     atak3();
    method Bit#(1)     atak4();
    method Bit#(1)     atak5();
    method Bit#(1)     atak6();
    method Bit#(1)     atak7();
    method Bit#(1)     eemph0();
    method Bit#(1)     eemph1();
    method Bit#(1)     eemph2();
    method Bit#(1)     eemph3();
    method Bit#(1)     eemph4();
    method Bit#(1)     eemph5();
    method Bit#(1)     eemph6();
    method Bit#(1)     eemph7();
    method Bit#(1)     etectrx0();
    method Bit#(1)     etectrx1();
    method Bit#(1)     etectrx2();
    method Bit#(1)     etectrx3();
    method Bit#(1)     etectrx4();
    method Bit#(1)     etectrx5();
    method Bit#(1)     etectrx6();
    method Bit#(1)     etectrx7();
endinterface
(* always_ready, always_enabled *)
interface PciewrapTxe;
    method Bit#(1)     lecidle0();
    method Bit#(1)     lecidle1();
    method Bit#(1)     lecidle2();
    method Bit#(1)     lecidle3();
    method Bit#(1)     lecidle4();
    method Bit#(1)     lecidle5();
    method Bit#(1)     lecidle6();
    method Bit#(1)     lecidle7();
endinterface
(* always_ready, always_enabled *)
interface PciewrapTxm;
    method Bit#(3)     argin0();
    method Bit#(3)     argin1();
    method Bit#(3)     argin2();
    method Bit#(3)     argin3();
    method Bit#(3)     argin4();
    method Bit#(3)     argin5();
    method Bit#(3)     argin6();
    method Bit#(3)     argin7();
endinterface
(* always_ready, always_enabled *)
interface PciewrapTxs;
    method Bit#(1)     wing0();
    method Bit#(1)     wing1();
    method Bit#(1)     wing2();
    method Bit#(1)     wing3();
    method Bit#(1)     wing4();
    method Bit#(1)     wing5();
    method Bit#(1)     wing6();
    method Bit#(1)     wing7();
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
    interface PciewrapInt_s     int_s;
    interface PciewrapKo     ko;
    interface PciewrapL2     l2;
    interface PciewrapLane     lane;
    interface PciewrapLmi     lmi;
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
    interface PciewrapRx_s     rx_s;
    interface PciewrapRxd     rxd;
    interface PciewrapRxe     rxe;
    interface PciewrapRxp     rxp;
    interface PciewrapRxs     rxs;
    interface PciewrapRxv     rxv;
    interface PciewrapSerdes     serdes;
    interface PciewrapSim     sim;
    interface PciewrapSimu     simu;
    interface PciewrapTest     test;
    interface PciewrapTestin     testin;
    interface PciewrapTl     tl;
    interface PciewrapTx_cred     tx_cred;
    interface PciewrapTx     tx;
    interface PciewrapTx_par     tx_par;
    interface PciewrapTx_s     tx_s;
    interface PciewrapTxc     txc;
    interface PciewrapTxd     txd;
    interface PciewrapTxe     txe;
    interface PciewrapTxm     txm;
    interface PciewrapTxs     txs;
endinterface
import "BVI" altera_pcie_sv_hip_ast_wrapper =
module mkPcieWrap#(Clock refclk, Reset npor, Reset pin_perst, Reset refclk_reset)(PcieWrap);
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
        method currentspeed speed()clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapDerr     derr;
        method derr_cor_ext_rcv cor_ext_rcv()clocked_by(coreclkout.hip);
        method derr_cor_ext_rpl cor_ext_rpl()clocked_by(coreclkout.hip);
        method derr_rpl rpl()clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapDl     dl;
        method dlup up()clocked_by(coreclkout.hip);
        method dlup_exit up_exit()clocked_by(coreclkout.hip);
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
        method hotrst_exit exit()clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapHpg     hpg;
        method ctrler(hpg_ctrler) enable((*inhigh*) EN_hpg_ctrler);
    endinterface
    interface PciewrapInt_s     int_s;
        method int_status tatus()clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapKo     ko;
        method ko_cpl_spc_data cpl_spc_data()clocked_by(coreclkout.hip);
        method ko_cpl_spc_header cpl_spc_header()clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapL2     l2;
        method l2_exit exit()clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapLane     lane;
        method lane_act act()clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapLmi     lmi;
        method lmi_ack ack() clocked_by(coreclkout_hip);
        method addr(lmi_addr) clocked_by(coreclkout_hip) enable((*inhigh*) EN_lmi_addr);
        method din(lmi_din) clocked_by(coreclkout_hip) enable((*inhigh*) EN_lmi_din);
        method lmi_dout dout() clocked_by(coreclkout_hip);
        method rden(lmi_rden) clocked_by(coreclkout_hip) enable((*inhigh*) EN_lmi_rden);
        method wren(lmi_wren) clocked_by(coreclkout_hip) enable((*inhigh*) EN_lmi_wren);
    endinterface
    interface PciewrapLtssm     ltssm;
        method ltssmstate state()clocked_by(coreclkout.hip);
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
    endinterface
    interface PciewrapRx_par     rx_par;
        method rx_par_err err()clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapRx_s     rx_s;
        method rx_st_bar t_bar() clocked_by(coreclkout.hip);
        method rx_st_be t_be() clocked_by(coreclkout.hip);
        method rx_st_data t_data() clocked_by(coreclkout.hip);
        method rx_st_empty t_empty() clocked_by(coreclkout.hip);
        method rx_st_eop t_eop() clocked_by(coreclkout.hip);
        method rx_st_err t_err() clocked_by(coreclkout.hip);
        method t_mask(rx_st_mask) clocked_by(coreclkout.hip) enable((*inhigh*) EN_rx_st_mask);
        method t_ready(rx_st_ready) clocked_by(coreclkout.hip) enable((*inhigh*) EN_rx_st_ready);
        method rx_st_sop t_sop() clocked_by(coreclkout.hip);
        method rx_st_valid t_valid() clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapRxd     rxd;
        method ata0(rxdata0) enable((*inhigh*) EN_rxdata0);
        method ata1(rxdata1) enable((*inhigh*) EN_rxdata1);
        method ata2(rxdata2) enable((*inhigh*) EN_rxdata2);
        method ata3(rxdata3) enable((*inhigh*) EN_rxdata3);
        method ata4(rxdata4) enable((*inhigh*) EN_rxdata4);
        method ata5(rxdata5) enable((*inhigh*) EN_rxdata5);
        method ata6(rxdata6) enable((*inhigh*) EN_rxdata6);
        method ata7(rxdata7) enable((*inhigh*) EN_rxdata7);
        method atak0(rxdatak0) enable((*inhigh*) EN_rxdatak0);
        method atak1(rxdatak1) enable((*inhigh*) EN_rxdatak1);
        method atak2(rxdatak2) enable((*inhigh*) EN_rxdatak2);
        method atak3(rxdatak3) enable((*inhigh*) EN_rxdatak3);
        method atak4(rxdatak4) enable((*inhigh*) EN_rxdatak4);
        method atak5(rxdatak5) enable((*inhigh*) EN_rxdatak5);
        method atak6(rxdatak6) enable((*inhigh*) EN_rxdatak6);
        method atak7(rxdatak7) enable((*inhigh*) EN_rxdatak7);
    endinterface
    interface PciewrapRxe     rxe;
        method lecidle0(rxelecidle0) enable((*inhigh*) EN_rxelecidle0);
        method lecidle1(rxelecidle1) enable((*inhigh*) EN_rxelecidle1);
        method lecidle2(rxelecidle2) enable((*inhigh*) EN_rxelecidle2);
        method lecidle3(rxelecidle3) enable((*inhigh*) EN_rxelecidle3);
        method lecidle4(rxelecidle4) enable((*inhigh*) EN_rxelecidle4);
        method lecidle5(rxelecidle5) enable((*inhigh*) EN_rxelecidle5);
        method lecidle6(rxelecidle6) enable((*inhigh*) EN_rxelecidle6);
        method lecidle7(rxelecidle7) enable((*inhigh*) EN_rxelecidle7);
    endinterface
    interface PciewrapRxp     rxp;
        method rxpolarity0 olarity0();
        method rxpolarity1 olarity1();
        method rxpolarity2 olarity2();
        method rxpolarity3 olarity3();
        method rxpolarity4 olarity4();
        method rxpolarity5 olarity5();
        method rxpolarity6 olarity6();
        method rxpolarity7 olarity7();
    endinterface
    interface PciewrapRxs     rxs;
        method tatus0(rxstatus0) enable((*inhigh*) EN_rxstatus0);
        method tatus1(rxstatus1) enable((*inhigh*) EN_rxstatus1);
        method tatus2(rxstatus2) enable((*inhigh*) EN_rxstatus2);
        method tatus3(rxstatus3) enable((*inhigh*) EN_rxstatus3);
        method tatus4(rxstatus4) enable((*inhigh*) EN_rxstatus4);
        method tatus5(rxstatus5) enable((*inhigh*) EN_rxstatus5);
        method tatus6(rxstatus6) enable((*inhigh*) EN_rxstatus6);
        method tatus7(rxstatus7) enable((*inhigh*) EN_rxstatus7);
    endinterface
    interface PciewrapRxv     rxv;
        method alid0(rxvalid0) enable((*inhigh*) EN_rxvalid0);
        method alid1(rxvalid1) enable((*inhigh*) EN_rxvalid1);
        method alid2(rxvalid2) enable((*inhigh*) EN_rxvalid2);
        method alid3(rxvalid3) enable((*inhigh*) EN_rxvalid3);
        method alid4(rxvalid4) enable((*inhigh*) EN_rxvalid4);
        method alid5(rxvalid5) enable((*inhigh*) EN_rxvalid5);
        method alid6(rxvalid6) enable((*inhigh*) EN_rxvalid6);
        method alid7(rxvalid7) enable((*inhigh*) EN_rxvalid7);
    endinterface
    interface PciewrapSerdes     serdes;
        method serdes_pll_locked pll_locked()clocked_by(coreclkout_hip);
    endinterface
    interface PciewrapSim     sim;
        method sim_ltssmstate ltssmstate();
        method pipe_pclk_in(sim_pipe_pclk_in) enable((*inhigh*) EN_sim_pipe_pclk_in);
        method sim_pipe_rate pipe_rate();
    endinterface
    interface PciewrapSimu     simu;
        method mode_pipe(simu_mode_pipe) enable((*inhigh*) EN_simu_mode_pipe);
    endinterface
    interface PciewrapTest     test;
        method in(test_in) enable((*inhigh*) EN_test_in);
    endinterface
    interface PciewrapTestin     testin;
        method testin_zero zero();
    endinterface
    interface PciewrapTl     tl;
        method tl_cfg_add cfg_add() clocked_by(coreclkout_hip);
        method tl_cfg_ctl cfg_ctl() clocked_by(coreclkout_hip);
        method tl_cfg_sts cfg_sts() clocked_by(coreclkout_hip);
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
    endinterface
    interface PciewrapTx_par     tx_par;
        method tx_par_err err()clocked_by(coreclkout.hip);
    endinterface
    interface PciewrapTx_s     tx_s;
        method t_data(tx_st_data) clocked_by(coreclkout.hip) enable((*inhigh*) EN_tx_st_data);
        method t_empty(tx_st_empty) clocked_by(coreclkout.hip) enable((*inhigh*) EN_tx_st_empty);
        method t_eop(tx_st_eop) clocked_by(coreclkout.hip) enable((*inhigh*) EN_tx_st_eop);
        method t_err(tx_st_err) clocked_by(coreclkout_hip) enable((*inhigh*) EN_tx_st_err);
        method tx_st_ready t_ready() clocked_by(coreclkout.hip);
        method t_sop(tx_st_sop) clocked_by(coreclkout.hip) enable((*inhigh*) EN_tx_st_sop);
        method t_valid(tx_st_valid) clocked_by(coreclkout.hip) enable((*inhigh*) EN_tx_st_valid);
    endinterface
    interface PciewrapTxc     txc;
        method txcompl0 ompl0();
        method txcompl1 ompl1();
        method txcompl2 ompl2();
        method txcompl3 ompl3();
        method txcompl4 ompl4();
        method txcompl5 ompl5();
        method txcompl6 ompl6();
        method txcompl7 ompl7();
    endinterface
    interface PciewrapTxd     txd;
        method txdata0 ata0();
        method txdata1 ata1();
        method txdata2 ata2();
        method txdata3 ata3();
        method txdata4 ata4();
        method txdata5 ata5();
        method txdata6 ata6();
        method txdata7 ata7();
        method txdatak0 atak0();
        method txdatak1 atak1();
        method txdatak2 atak2();
        method txdatak3 atak3();
        method txdatak4 atak4();
        method txdatak5 atak5();
        method txdatak6 atak6();
        method txdatak7 atak7();
        method txdeemph0 eemph0();
        method txdeemph1 eemph1();
        method txdeemph2 eemph2();
        method txdeemph3 eemph3();
        method txdeemph4 eemph4();
        method txdeemph5 eemph5();
        method txdeemph6 eemph6();
        method txdeemph7 eemph7();
        method txdetectrx0 etectrx0();
        method txdetectrx1 etectrx1();
        method txdetectrx2 etectrx2();
        method txdetectrx3 etectrx3();
        method txdetectrx4 etectrx4();
        method txdetectrx5 etectrx5();
        method txdetectrx6 etectrx6();
        method txdetectrx7 etectrx7();
    endinterface
    interface PciewrapTxe     txe;
        method txelecidle0 lecidle0();
        method txelecidle1 lecidle1();
        method txelecidle2 lecidle2();
        method txelecidle3 lecidle3();
        method txelecidle4 lecidle4();
        method txelecidle5 lecidle5();
        method txelecidle6 lecidle6();
        method txelecidle7 lecidle7();
    endinterface
    interface PciewrapTxm     txm;
        method txmargin0 argin0();
        method txmargin1 argin1();
        method txmargin2 argin2();
        method txmargin3 argin3();
        method txmargin4 argin4();
        method txmargin5 argin5();
        method txmargin6 argin6();
        method txmargin7 argin7();
    endinterface
    interface PciewrapTxs     txs;
        method txswing0 wing0();
        method txswing1 wing1();
        method txswing2 wing2();
        method txswing3 wing3();
        method txswing4 wing4();
        method txswing5 wing5();
        method txswing6 wing6();
        method txswing7 wing7();
    endinterface
    schedule (app.int_ack, app.int_sts, app.msi_ack, app.msi_num, app.msi_req, app.msi_tc, cfg_par.err, cpl.err, cpl.pending, current.speed, derr.cor_ext_rcv, derr.cor_ext_rpl, derr.rpl, dl.up, dl.up_exit, eidle.infersel0, eidle.infersel1, eidle.infersel2, eidle.infersel3, eidle.infersel4, eidle.infersel5, eidle.infersel6, eidle.infersel7, ev128.ns, ev1.us, hotrst.exit, hpg.ctrler, int_s.tatus, ko.cpl_spc_data, ko.cpl_spc_header, l2.exit, lane.act, lmi.ack, lmi.addr, lmi.din, lmi.dout, lmi.rden, lmi.wren, ltssm.state, phy.status0, phy.status1, phy.status2, phy.status3, phy.status4, phy.status5, phy.status6, phy.status7, pld.clk, pld.clk_inuse, pld.core_ready, pm.auxpwr, pm.data, pm_e.vent, pme.to_cr, pme.to_sr, power.down0, power.down1, power.down2, power.down3, power.down4, power.down5, power.down6, power.down7, reconfig.from_xcvr, reconfig.to_xcvr, rx.in0, rx.in1, rx.in2, rx.in3, rx.in4, rx.in5, rx.in6, rx.in7, rx_par.err, rx_s.t_bar, rx_s.t_be, rx_s.t_data, rx_s.t_empty, rx_s.t_eop, rx_s.t_err, rx_s.t_mask, rx_s.t_ready, rx_s.t_sop, rx_s.t_valid, rxd.ata0, rxd.ata1, rxd.ata2, rxd.ata3, rxd.ata4, rxd.ata5, rxd.ata6, rxd.ata7, rxd.atak0, rxd.atak1, rxd.atak2, rxd.atak3, rxd.atak4, rxd.atak5, rxd.atak6, rxd.atak7, rxe.lecidle0, rxe.lecidle1, rxe.lecidle2, rxe.lecidle3, rxe.lecidle4, rxe.lecidle5, rxe.lecidle6, rxe.lecidle7, rxp.olarity0, rxp.olarity1, rxp.olarity2, rxp.olarity3, rxp.olarity4, rxp.olarity5, rxp.olarity6, rxp.olarity7, rxs.tatus0, rxs.tatus1, rxs.tatus2, rxs.tatus3, rxs.tatus4, rxs.tatus5, rxs.tatus6, rxs.tatus7, rxv.alid0, rxv.alid1, rxv.alid2, rxv.alid3, rxv.alid4, rxv.alid5, rxv.alid6, rxv.alid7, serdes.pll_locked, sim.ltssmstate, sim.pipe_pclk_in, sim.pipe_rate, simu.mode_pipe, test.in, testin.zero, tl.cfg_add, tl.cfg_ctl, tl.cfg_sts, tx_cred.datafccp, tx_cred.datafcnp, tx_cred.datafcp, tx_cred.fchipcons, tx_cred.fcinfinite, tx_cred.hdrfccp, tx_cred.hdrfcnp, tx_cred.hdrfcp, tx.out0, tx.out1, tx.out2, tx.out3, tx.out4, tx.out5, tx.out6, tx.out7, tx_par.err, tx_s.t_data, tx_s.t_empty, tx_s.t_eop, tx_s.t_err, tx_s.t_ready, tx_s.t_sop, tx_s.t_valid, txc.ompl0, txc.ompl1, txc.ompl2, txc.ompl3, txc.ompl4, txc.ompl5, txc.ompl6, txc.ompl7, txd.ata0, txd.ata1, txd.ata2, txd.ata3, txd.ata4, txd.ata5, txd.ata6, txd.ata7, txd.atak0, txd.atak1, txd.atak2, txd.atak3, txd.atak4, txd.atak5, txd.atak6, txd.atak7, txd.eemph0, txd.eemph1, txd.eemph2, txd.eemph3, txd.eemph4, txd.eemph5, txd.eemph6, txd.eemph7, txd.etectrx0, txd.etectrx1, txd.etectrx2, txd.etectrx3, txd.etectrx4, txd.etectrx5, txd.etectrx6, txd.etectrx7, txe.lecidle0, txe.lecidle1, txe.lecidle2, txe.lecidle3, txe.lecidle4, txe.lecidle5, txe.lecidle6, txe.lecidle7, txm.argin0, txm.argin1, txm.argin2, txm.argin3, txm.argin4, txm.argin5, txm.argin6, txm.argin7, txs.wing0, txs.wing1, txs.wing2, txs.wing3, txs.wing4, txs.wing5, txs.wing6, txs.wing7) CF (app.int_ack, app.int_sts, app.msi_ack, app.msi_num, app.msi_req, app.msi_tc, cfg_par.err, cpl.err, cpl.pending, current.speed, derr.cor_ext_rcv, derr.cor_ext_rpl, derr.rpl, dl.up, dl.up_exit, eidle.infersel0, eidle.infersel1, eidle.infersel2, eidle.infersel3, eidle.infersel4, eidle.infersel5, eidle.infersel6, eidle.infersel7, ev128.ns, ev1.us, hotrst.exit, hpg.ctrler, int_s.tatus, ko.cpl_spc_data, ko.cpl_spc_header, l2.exit, lane.act, lmi.ack, lmi.addr, lmi.din, lmi.dout, lmi.rden, lmi.wren, ltssm.state, phy.status0, phy.status1, phy.status2, phy.status3, phy.status4, phy.status5, phy.status6, phy.status7, pld.clk, pld.clk_inuse, pld.core_ready, pm.auxpwr, pm.data, pm_e.vent, pme.to_cr, pme.to_sr, power.down0, power.down1, power.down2, power.down3, power.down4, power.down5, power.down6, power.down7, reconfig.from_xcvr, reconfig.to_xcvr, rx.in0, rx.in1, rx.in2, rx.in3, rx.in4, rx.in5, rx.in6, rx.in7, rx_par.err, rx_s.t_bar, rx_s.t_be, rx_s.t_data, rx_s.t_empty, rx_s.t_eop, rx_s.t_err, rx_s.t_mask, rx_s.t_ready, rx_s.t_sop, rx_s.t_valid, rxd.ata0, rxd.ata1, rxd.ata2, rxd.ata3, rxd.ata4, rxd.ata5, rxd.ata6, rxd.ata7, rxd.atak0, rxd.atak1, rxd.atak2, rxd.atak3, rxd.atak4, rxd.atak5, rxd.atak6, rxd.atak7, rxe.lecidle0, rxe.lecidle1, rxe.lecidle2, rxe.lecidle3, rxe.lecidle4, rxe.lecidle5, rxe.lecidle6, rxe.lecidle7, rxp.olarity0, rxp.olarity1, rxp.olarity2, rxp.olarity3, rxp.olarity4, rxp.olarity5, rxp.olarity6, rxp.olarity7, rxs.tatus0, rxs.tatus1, rxs.tatus2, rxs.tatus3, rxs.tatus4, rxs.tatus5, rxs.tatus6, rxs.tatus7, rxv.alid0, rxv.alid1, rxv.alid2, rxv.alid3, rxv.alid4, rxv.alid5, rxv.alid6, rxv.alid7, serdes.pll_locked, sim.ltssmstate, sim.pipe_pclk_in, sim.pipe_rate, simu.mode_pipe, test.in, testin.zero, tl.cfg_add, tl.cfg_ctl, tl.cfg_sts, tx_cred.datafccp, tx_cred.datafcnp, tx_cred.datafcp, tx_cred.fchipcons, tx_cred.fcinfinite, tx_cred.hdrfccp, tx_cred.hdrfcnp, tx_cred.hdrfcp, tx.out0, tx.out1, tx.out2, tx.out3, tx.out4, tx.out5, tx.out6, tx.out7, tx_par.err, tx_s.t_data, tx_s.t_empty, tx_s.t_eop, tx_s.t_err, tx_s.t_ready, tx_s.t_sop, tx_s.t_valid, txc.ompl0, txc.ompl1, txc.ompl2, txc.ompl3, txc.ompl4, txc.ompl5, txc.ompl6, txc.ompl7, txd.ata0, txd.ata1, txd.ata2, txd.ata3, txd.ata4, txd.ata5, txd.ata6, txd.ata7, txd.atak0, txd.atak1, txd.atak2, txd.atak3, txd.atak4, txd.atak5, txd.atak6, txd.atak7, txd.eemph0, txd.eemph1, txd.eemph2, txd.eemph3, txd.eemph4, txd.eemph5, txd.eemph6, txd.eemph7, txd.etectrx0, txd.etectrx1, txd.etectrx2, txd.etectrx3, txd.etectrx4, txd.etectrx5, txd.etectrx6, txd.etectrx7, txe.lecidle0, txe.lecidle1, txe.lecidle2, txe.lecidle3, txe.lecidle4, txe.lecidle5, txe.lecidle6, txe.lecidle7, txm.argin0, txm.argin1, txm.argin2, txm.argin3, txm.argin4, txm.argin5, txm.argin6, txm.argin7, txs.wing0, txs.wing1, txs.wing2, txs.wing3, txs.wing4, txs.wing5, txs.wing6, txs.wing7);
endmodule
