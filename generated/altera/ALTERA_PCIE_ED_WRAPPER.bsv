
/*
   ./importbvi.py
   -o
   ALTERA_PCIE_ED_WRAPPER.bsv
   -I
   PcieEdWrap
   -P
   PcieEdWrap
   -c
   coreclkout_hip
   -c
   pld_clk_hip
   -f
   serdes
   -f
   reset
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
   int_s
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
   tx_s
   -f
   rx_s
   -f
   tx_cred
   -f
   tx_par
   -f
   rx_par
   -f
   cfg_par
   ../../out/de5/synthesis/altera_pcie_hip_ast_ed.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface PcieedwrapApp;
    method Action      int_ack(Bit#(1) v);
    method Bit#(1)     int_sts();
    method Action      msi_ack(Bit#(1) v);
    method Bit#(5)     msi_num();
    method Bit#(1)     msi_req();
    method Bit#(3)     msi_tc();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapCfg_par;
    method Action      err(Bit#(1) v);
    method Bit#(1)     err_drv();
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface PcieedwrapCpl;
    method Bit#(7)     err();
    method Bit#(1)     pending();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapDerr;
    method Action      cor_ext_rcv(Bit#(1) v);
    method Bit#(1)     cor_ext_rcv_drv();
    method Action      cor_ext_rpl(Bit#(1) v);
    method Bit#(1)     cor_ext_rpl_drv();
    method Action      rpl(Bit#(1) v);
    method Bit#(1)     rpl_drv();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapDl;
    method Action      up(Bit#(1) v);
    method Bit#(1)     up_drv();
    method Action      up_exit(Bit#(1) v);
    method Bit#(1)     up_exit_drv();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapEv1;
    method Action      us(Bit#(1) v);
    method Bit#(1)     us_drv();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapEv128;
    method Action      ns(Bit#(1) v);
    method Bit#(1)     ns_drv();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapHotrst;
    method Action      exit(Bit#(1) v);
    method Bit#(1)     exit_drv();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapHpg;
    method Bit#(5)     ctrler();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapInt_s;
    method Action      tatus(Bit#(4) v);
    method Bit#(4)     tatus_drv();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapKo;
    method Action      cpl_spc_data(Bit#(12) v);
    method Bit#(12)     cpl_spc_data_drv();
    method Action      cpl_spc_header(Bit#(8) v);
    method Bit#(8)     cpl_spc_header_drv();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapL2;
    method Action      exit(Bit#(1) v);
    method Bit#(1)     exit_drv();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapLane;
    method Action      act(Bit#(4) v);
    method Bit#(4)     act_drv();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapLmi;
    method Action      ack(Bit#(1) v);
    method Bit#(12)     addr();
    method Bit#(32)     din();
    method Action      dout(Bit#(32) v);
    method Bit#(1)     rden();
    method Bit#(1)     wren();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapLtssm;
    method Action      state(Bit#(5) v);
    method Bit#(5)     state_drv();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapPld;
    interface Clock     clk_hip;
    method Action      clk_inuse(Bit#(1) v);
    method Bit#(1)     core_ready();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapPm;
    method Bit#(1)     auxpwr();
    method Bit#(10)     data();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapPm_e;
    method Bit#(1)     vent();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapPme;
    method Bit#(1)     to_cr();
    method Action      to_sr(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapReset;
    method Action      status(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapRx_par;
    method Action      err(Bit#(1) v);
    method Bit#(1)     err_drv();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapRx_s;
    method Action      t_bar(Bit#(8) v);
    method Action      t_be(Bit#(16) v);
    method Action      t_data(Bit#(128) v);
    method Action      t_empty(Bit#(2) v);
    method Action      t_eop(Bit#(1) v);
    method Action      t_err(Bit#(1) v);
    method Bit#(1)     t_mask();
    method Bit#(1)     t_ready();
    method Action      t_sop(Bit#(1) v);
    method Action      t_valid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapSerdes;
    method Action      pll_locked(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapTestin;
    method Action      zero(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapTl;
    method Action      cfg_add(Bit#(4) v);
    method Action      cfg_ctl(Bit#(32) v);
    method Action      cfg_sts(Bit#(53) v);
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapTx_cred;
    method Action      datafccp(Bit#(12) v);
    method Action      datafcnp(Bit#(12) v);
    method Action      datafcp(Bit#(12) v);
    method Action      fchipcons(Bit#(6) v);
    method Action      fcinfinite(Bit#(6) v);
    method Action      hdrfccp(Bit#(8) v);
    method Action      hdrfcnp(Bit#(8) v);
    method Action      hdrfcp(Bit#(8) v);
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapTx_par;
    method Action      err(Bit#(2) v);
    method Bit#(2)     err_drv();
endinterface
(* always_ready, always_enabled *)
interface PcieedwrapTx_s;
    method Bit#(128)     t_data();
    method Bit#(2)     t_empty();
    method Bit#(1)     t_eop();
    method Bit#(1)     t_err();
    method Action      t_ready(Bit#(1) v);
    method Bit#(1)     t_sop();
    method Bit#(1)     t_valid();
endinterface
(* always_ready, always_enabled *)
interface PcieEdWrap;
    interface PcieedwrapApp     app;
    interface PcieedwrapCfg_par     cfg_par;
    interface PcieedwrapCpl     cpl;
    interface PcieedwrapDerr     derr;
    interface PcieedwrapDl     dl;
    interface PcieedwrapEv128     ev128;
    interface PcieedwrapEv1     ev1;
    interface PcieedwrapHotrst     hotrst;
    interface PcieedwrapHpg     hpg;
    interface PcieedwrapInt_s     int_s;
    interface PcieedwrapKo     ko;
    interface PcieedwrapL2     l2;
    interface PcieedwrapLane     lane;
    interface PcieedwrapLmi     lmi;
    interface PcieedwrapLtssm     ltssm;
    interface PcieedwrapPld     pld;
    interface PcieedwrapPm     pm;
    interface PcieedwrapPm_e     pm_e;
    interface PcieedwrapPme     pme;
    interface PcieedwrapReset     reset;
    interface PcieedwrapRx_par     rx_par;
    interface PcieedwrapRx_s     rx_s;
    interface PcieedwrapSerdes     serdes;
    interface PcieedwrapTestin     testin;
    interface PcieedwrapTl     tl;
    interface PcieedwrapTx_cred     tx_cred;
    interface PcieedwrapTx_par     tx_par;
    interface PcieedwrapTx_s     tx_s;
endinterface
import "BVI" altera_pcie_hip_ast_ed =
module mkPcieEdWrap#(Clock coreclkout_hip, Reset coreclkout_hip_reset)(PcieEdWrap);
    default_clock clk();
    default_reset rst();
        input_clock coreclkout_hip(coreclkout_hip) = coreclkout_hip;
        input_reset coreclkout_hip_reset() = coreclkout_hip_reset; /* from clock*/
    interface PcieedwrapApp     app;
        method int_ack(app_int_ack) enable((*inhigh*) EN_app_int_ack);
        method app_int_sts int_sts();
        method msi_ack(app_msi_ack) enable((*inhigh*) EN_app_msi_ack);
        method app_msi_num msi_num();
        method app_msi_req msi_req();
        method app_msi_tc msi_tc();
    endinterface
    interface PcieedwrapCfg_par     cfg_par;
        method err(cfg_par_err) enable((*inhigh*) EN_cfg_par_err);
        method cfg_par_err_drv err_drv();
    endinterface
    interface PcieedwrapCpl     cpl;
        method cpl_err err();
        method cpl_pending pending();
    endinterface
    interface PcieedwrapDerr     derr;
        method cor_ext_rcv(derr_cor_ext_rcv) enable((*inhigh*) EN_derr_cor_ext_rcv);
        method derr_cor_ext_rcv_drv cor_ext_rcv_drv();
        method cor_ext_rpl(derr_cor_ext_rpl) enable((*inhigh*) EN_derr_cor_ext_rpl);
        method derr_cor_ext_rpl_drv cor_ext_rpl_drv();
        method rpl(derr_rpl) enable((*inhigh*) EN_derr_rpl);
        method derr_rpl_drv rpl_drv();
    endinterface
    interface PcieedwrapDl     dl;
        method up(dlup) enable((*inhigh*) EN_dlup);
        method dlup_drv up_drv();
        method up_exit(dlup_exit) enable((*inhigh*) EN_dlup_exit);
        method dlup_exit_drv up_exit_drv();
    endinterface
    interface PcieedwrapEv128     ev128;
        method ns(ev128ns) enable((*inhigh*) EN_ev128ns);
        method ev128ns_drv ns_drv();
    endinterface
    interface PcieedwrapEv1     ev1;
        method us(ev1us) enable((*inhigh*) EN_ev1us);
        method ev1us_drv us_drv();
    endinterface
    interface PcieedwrapHotrst     hotrst;
        method exit(hotrst_exit) enable((*inhigh*) EN_hotrst_exit);
        method hotrst_exit_drv exit_drv();
    endinterface
    interface PcieedwrapHpg     hpg;
        method hpg_ctrler ctrler();
    endinterface
    interface PcieedwrapInt_s     int_s;
        method tatus(int_status) enable((*inhigh*) EN_int_status);
        method int_status_drv tatus_drv();
    endinterface
    interface PcieedwrapKo     ko;
        method cpl_spc_data(ko_cpl_spc_data) enable((*inhigh*) EN_ko_cpl_spc_data);
        method ko_cpl_spc_data_drv cpl_spc_data_drv();
        method cpl_spc_header(ko_cpl_spc_header) enable((*inhigh*) EN_ko_cpl_spc_header);
        method ko_cpl_spc_header_drv cpl_spc_header_drv();
    endinterface
    interface PcieedwrapL2     l2;
        method exit(l2_exit) enable((*inhigh*) EN_l2_exit);
        method l2_exit_drv exit_drv();
    endinterface
    interface PcieedwrapLane     lane;
        method act(lane_act) enable((*inhigh*) EN_lane_act);
        method lane_act_drv act_drv();
    endinterface
    interface PcieedwrapLmi     lmi;
        method ack(lmi_ack) enable((*inhigh*) EN_lmi_ack);
        method lmi_addr addr();
        method lmi_din din();
        method dout(lmi_dout) enable((*inhigh*) EN_lmi_dout);
        method lmi_rden rden();
        method lmi_wren wren();
    endinterface
    interface PcieedwrapLtssm     ltssm;
        method state(ltssmstate) enable((*inhigh*) EN_ltssmstate);
        method ltssmstate_drv state_drv();
    endinterface
    interface PcieedwrapPld     pld;
        output_clock clk_hip(pld_clk_hip);
        method clk_inuse(pld_clk_inuse) enable((*inhigh*) EN_pld_clk_inuse);
        method pld_core_ready core_ready();
    endinterface
    interface PcieedwrapPm     pm;
        method pm_auxpwr auxpwr();
        method pm_data data();
    endinterface
    interface PcieedwrapPm_e     pm_e;
        method pm_event vent();
    endinterface
    interface PcieedwrapPme     pme;
        method pme_to_cr to_cr();
        method to_sr(pme_to_sr) enable((*inhigh*) EN_pme_to_sr);
    endinterface
    interface PcieedwrapReset     reset;
        method status(reset_status) enable((*inhigh*) EN_reset_status);
    endinterface
    interface PcieedwrapRx_par     rx_par;
        method err(rx_par_err) enable((*inhigh*) EN_rx_par_err);
        method rx_par_err_drv err_drv();
    endinterface
    interface PcieedwrapRx_s     rx_s;
        method t_bar(rx_st_bar) enable((*inhigh*) EN_rx_st_bar);
        method t_be(rx_st_be) enable((*inhigh*) EN_rx_st_be);
        method t_data(rx_st_data) enable((*inhigh*) EN_rx_st_data);
        method t_empty(rx_st_empty) enable((*inhigh*) EN_rx_st_empty);
        method t_eop(rx_st_eop) enable((*inhigh*) EN_rx_st_eop);
        method t_err(rx_st_err) enable((*inhigh*) EN_rx_st_err);
        method rx_st_mask t_mask();
        method rx_st_ready t_ready();
        method t_sop(rx_st_sop) enable((*inhigh*) EN_rx_st_sop);
        method t_valid(rx_st_valid) enable((*inhigh*) EN_rx_st_valid);
    endinterface
    interface PcieedwrapSerdes     serdes;
        method pll_locked(serdes_pll_locked) enable((*inhigh*) EN_serdes_pll_locked);
    endinterface
    interface PcieedwrapTestin     testin;
        method zero(testin_zero) enable((*inhigh*) EN_testin_zero);
    endinterface
    interface PcieedwrapTl     tl;
        method cfg_add(tl_cfg_add) enable((*inhigh*) EN_tl_cfg_add);
        method cfg_ctl(tl_cfg_ctl) enable((*inhigh*) EN_tl_cfg_ctl);
        method cfg_sts(tl_cfg_sts) enable((*inhigh*) EN_tl_cfg_sts);
    endinterface
    interface PcieedwrapTx_cred     tx_cred;
        method datafccp(tx_cred_datafccp) enable((*inhigh*) EN_tx_cred_datafccp);
        method datafcnp(tx_cred_datafcnp) enable((*inhigh*) EN_tx_cred_datafcnp);
        method datafcp(tx_cred_datafcp) enable((*inhigh*) EN_tx_cred_datafcp);
        method fchipcons(tx_cred_fchipcons) enable((*inhigh*) EN_tx_cred_fchipcons);
        method fcinfinite(tx_cred_fcinfinite) enable((*inhigh*) EN_tx_cred_fcinfinite);
        method hdrfccp(tx_cred_hdrfccp) enable((*inhigh*) EN_tx_cred_hdrfccp);
        method hdrfcnp(tx_cred_hdrfcnp) enable((*inhigh*) EN_tx_cred_hdrfcnp);
        method hdrfcp(tx_cred_hdrfcp) enable((*inhigh*) EN_tx_cred_hdrfcp);
    endinterface
    interface PcieedwrapTx_par     tx_par;
        method err(tx_par_err) enable((*inhigh*) EN_tx_par_err);
        method tx_par_err_drv err_drv();
    endinterface
    interface PcieedwrapTx_s     tx_s;
        method tx_st_data t_data();
        method tx_st_empty t_empty();
        method tx_st_eop t_eop();
        method tx_st_err t_err();
        method t_ready(tx_st_ready) enable((*inhigh*) EN_tx_st_ready);
        method tx_st_sop t_sop();
        method tx_st_valid t_valid();
    endinterface
    schedule (app.int_ack, app.int_sts, app.msi_ack, app.msi_num, app.msi_req, app.msi_tc, cfg_par.err, cfg_par.err_drv, cpl.err, cpl.pending, derr.cor_ext_rcv, derr.cor_ext_rcv_drv, derr.cor_ext_rpl, derr.cor_ext_rpl_drv, derr.rpl, derr.rpl_drv, dl.up, dl.up_drv, dl.up_exit, dl.up_exit_drv, ev128.ns, ev128.ns_drv, ev1.us, ev1.us_drv, hotrst.exit, hotrst.exit_drv, hpg.ctrler, int_s.tatus, int_s.tatus_drv, ko.cpl_spc_data, ko.cpl_spc_data_drv, ko.cpl_spc_header, ko.cpl_spc_header_drv, l2.exit, l2.exit_drv, lane.act, lane.act_drv, lmi.ack, lmi.addr, lmi.din, lmi.dout, lmi.rden, lmi.wren, ltssm.state, ltssm.state_drv, pld.clk_inuse, pld.core_ready, pm.auxpwr, pm.data, pm_e.vent, pme.to_cr, pme.to_sr, reset.status, rx_par.err, rx_par.err_drv, rx_s.t_bar, rx_s.t_be, rx_s.t_data, rx_s.t_empty, rx_s.t_eop, rx_s.t_err, rx_s.t_mask, rx_s.t_ready, rx_s.t_sop, rx_s.t_valid, serdes.pll_locked, testin.zero, tl.cfg_add, tl.cfg_ctl, tl.cfg_sts, tx_cred.datafccp, tx_cred.datafcnp, tx_cred.datafcp, tx_cred.fchipcons, tx_cred.fcinfinite, tx_cred.hdrfccp, tx_cred.hdrfcnp, tx_cred.hdrfcp, tx_par.err, tx_par.err_drv, tx_s.t_data, tx_s.t_empty, tx_s.t_eop, tx_s.t_err, tx_s.t_ready, tx_s.t_sop, tx_s.t_valid) CF (app.int_ack, app.int_sts, app.msi_ack, app.msi_num, app.msi_req, app.msi_tc, cfg_par.err, cfg_par.err_drv, cpl.err, cpl.pending, derr.cor_ext_rcv, derr.cor_ext_rcv_drv, derr.cor_ext_rpl, derr.cor_ext_rpl_drv, derr.rpl, derr.rpl_drv, dl.up, dl.up_drv, dl.up_exit, dl.up_exit_drv, ev128.ns, ev128.ns_drv, ev1.us, ev1.us_drv, hotrst.exit, hotrst.exit_drv, hpg.ctrler, int_s.tatus, int_s.tatus_drv, ko.cpl_spc_data, ko.cpl_spc_data_drv, ko.cpl_spc_header, ko.cpl_spc_header_drv, l2.exit, l2.exit_drv, lane.act, lane.act_drv, lmi.ack, lmi.addr, lmi.din, lmi.dout, lmi.rden, lmi.wren, ltssm.state, ltssm.state_drv, pld.clk_inuse, pld.core_ready, pm.auxpwr, pm.data, pm_e.vent, pme.to_cr, pme.to_sr, reset.status, rx_par.err, rx_par.err_drv, rx_s.t_bar, rx_s.t_be, rx_s.t_data, rx_s.t_empty, rx_s.t_eop, rx_s.t_err, rx_s.t_mask, rx_s.t_ready, rx_s.t_sop, rx_s.t_valid, serdes.pll_locked, testin.zero, tl.cfg_add, tl.cfg_ctl, tl.cfg_sts, tx_cred.datafccp, tx_cred.datafcnp, tx_cred.datafcp, tx_cred.fchipcons, tx_cred.fcinfinite, tx_cred.hdrfccp, tx_cred.hdrfcnp, tx_cred.hdrfcp, tx_par.err, tx_par.err_drv, tx_s.t_data, tx_s.t_empty, tx_s.t_eop, tx_s.t_err, tx_s.t_ready, tx_s.t_sop, tx_s.t_valid);
endmodule
