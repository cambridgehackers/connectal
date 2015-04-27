
/*
   scripts/importbvi.py
   -o
   PCIEWRAPPER.bsv
   -I
   PcieWrap
   -P
   PcieWrap
   -n
   pl_link_partner_gen2_supported
   -n
   cfg_mgmt_wr_rw1c_as_rw
   -n
   pipe_gen3_out
   -n
   pipe_userclk1_in
   -n
   pipe_userclk2_in
   -n
   pl_link_gen2_cap
   -c
   user_clk_out
   -r
   user_reset_out
   -c
   sys_clk
   -r
   sys_rst_n
   -f
   cfg_aer
   -f
   cfg_ds
   -f
   cfg_err
   -f
   cfg_interrupt
   -f
   cfg_mgmt
   -f
   cfg_msg
   -f
   cfg_pmcsr
   -f
   cfg_pm
   -f
   cfg_root_control
   -f
   pipe
   -f
   pl_link
   -f
   pci_exp
   -f
   pcie_drp
   -p
   lanes
   ../../import_components/Xilinx/generated/kc705/pcie_7x_0/synth/pcie_7x_0.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface PciewrapCfg#(numeric type lanes);
    method Bit#(1)     bridge_serr_en();
    method Bit#(8)     bus_number();
    method Bit#(16)     command();
    method Bit#(16)     dcommand();
    method Bit#(16)     dcommand2();
    method Bit#(5)     device_number();
    method Bit#(3)     function_number();
    method Action      interrupt(Bit#(1) v);
    method Bit#(16)     lcommand();
    method Bit#(16)     lstatus();
    method Bit#(3)     pcie_link_state();
    method Action      pciecap_interrupt_msgnum(Bit#(5) v);
    method Bit#(1)     received_func_lvl_rst();
    method Bit#(1)     slot_control_electromech_il_ctl_pulse();
    method Bit#(16)     status();
    method Bit#(1)     to_turnoff();
    method Action      trn_pending(Bit#(1) v);
    method Action      turnoff_ok(Bit#(1) v);
    method Bit#(7)     vc_tcvc_map();
endinterface
(* always_ready, always_enabled *)
interface PciewrapCfg_aer#(numeric type lanes);
    method Bit#(1)     ecrc_check_en();
    method Bit#(1)     ecrc_gen_en();
    method Action      interrupt_msgnum(Bit#(5) v);
    method Bit#(1)     rooterr_corr_err_received();
    method Bit#(1)     rooterr_corr_err_reporting_en();
    method Bit#(1)     rooterr_fatal_err_received();
    method Bit#(1)     rooterr_fatal_err_reporting_en();
    method Bit#(1)     rooterr_non_fatal_err_received();
    method Bit#(1)     rooterr_non_fatal_err_reporting_en();
endinterface
(* always_ready, always_enabled *)
interface PciewrapCfg_ds#(numeric type lanes);
    method Action      bus_number(Bit#(8) v);
    method Action      device_number(Bit#(5) v);
    method Action      function_number(Bit#(3) v);
    method Action      n(Bit#(64) v);
    method Bit#(16)     tatus();
endinterface
(* always_ready, always_enabled *)
interface PciewrapCfg_err#(numeric type lanes);
    method Action      acs(Bit#(1) v);
    method Action      aer_headerlog(Bit#(128) v);
    method Bit#(1)     aer_headerlog_set();
    method Action      atomic_egress_blocked(Bit#(1) v);
    method Action      cor(Bit#(1) v);
    method Action      cpl_abort(Bit#(1) v);
    method Bit#(1)     cpl_rdy();
    method Action      cpl_timeout(Bit#(1) v);
    method Action      cpl_unexpect(Bit#(1) v);
    method Action      ecrc(Bit#(1) v);
    method Action      internal_cor(Bit#(1) v);
    method Action      internal_uncor(Bit#(1) v);
    method Action      locked(Bit#(1) v);
    method Action      malformed(Bit#(1) v);
    method Action      mc_blocked(Bit#(1) v);
    method Action      norecovery(Bit#(1) v);
    method Action      poisoned(Bit#(1) v);
    method Action      posted(Bit#(1) v);
    method Action      tlp_cpl_header(Bit#(48) v);
    method Action      ur(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapCfg_interrupt#(numeric type lanes);
    method Action      zzassert(Bit#(1) v);
    method Action      di(Bit#(8) v);
    method Bit#(8)     zzdo();
    method Bit#(3)     mmenable();
    method Bit#(1)     msienable();
    method Bit#(1)     msixenable();
    method Bit#(1)     msixfm();
    method Bit#(1)     rdy();
    method Action      stat(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapCfg_mgmt#(numeric type lanes);
    method Action      byte_en(Bit#(4) v);
    method Action      di(Bit#(32) v);
    method Bit#(32)     zzdo();
    method Action      dwaddr(Bit#(10) v);
    method Action      rd_en(Bit#(1) v);
    method Bit#(1)     rd_wr_done();
    method Action      wr_en(Bit#(1) v);
    method Action      wr_readonly(Bit#(1) v);
    method Action      wr_rw1c_as_rw(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapCfg_msg#(numeric type lanes);
    method Bit#(16)     data();
    method Bit#(1)     received();
    method Bit#(1)     received_assert_int_a();
    method Bit#(1)     received_assert_int_b();
    method Bit#(1)     received_assert_int_c();
    method Bit#(1)     received_assert_int_d();
    method Bit#(1)     received_deassert_int_a();
    method Bit#(1)     received_deassert_int_b();
    method Bit#(1)     received_deassert_int_c();
    method Bit#(1)     received_deassert_int_d();
    method Bit#(1)     received_err_cor();
    method Bit#(1)     received_err_fatal();
    method Bit#(1)     received_err_non_fatal();
    method Bit#(1)     received_pm_as_nak();
    method Bit#(1)     received_pm_pme();
    method Bit#(1)     received_pme_to_ack();
    method Bit#(1)     received_setslotpowerlimit();
endinterface
(* always_ready, always_enabled *)
interface PciewrapCfg_pm#(numeric type lanes);
    method Action      force_state(Bit#(2) v);
    method Action      force_state_en(Bit#(1) v);
    method Action      halt_aspm_l0s(Bit#(1) v);
    method Action      halt_aspm_l1(Bit#(1) v);
    method Action      send_pme_to(Bit#(1) v);
    method Action      wake(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapCfg_pmcsr#(numeric type lanes);
    method Bit#(1)     pme_en();
    method Bit#(1)     pme_status();
    method Bit#(2)     powerstate();
endinterface
(* always_ready, always_enabled *)
interface PciewrapCfg_root_control#(numeric type lanes);
    method Bit#(1)     pme_int_en();
    method Bit#(1)     syserr_corr_err_en();
    method Bit#(1)     syserr_fatal_err_en();
    method Bit#(1)     syserr_non_fatal_err_en();
endinterface
(* always_ready, always_enabled *)
interface PciewrapFc#(numeric type lanes);
    method Bit#(12)     cpld();
    method Bit#(8)     cplh();
    method Bit#(12)     npd();
    method Bit#(8)     nph();
    method Bit#(12)     pd();
    method Bit#(8)     ph();
    method Action      sel(Bit#(3) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapIcap#(numeric type lanes);
    method Action      clk(Bit#(1) v);
    method Action      csib(Bit#(1) v);
    method Action      i(Bit#(32) v);
    method Bit#(32)     o();
    method Action      rdwrb(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapM_axis_rx#(numeric type lanes);
    method Bit#(64)     tdata();
    method Bit#(8)     tkeep();
    method Bit#(1)     tlast();
    method Action      tready(Bit#(1) v);
    method Bit#(22)     tuser();
    method Bit#(1)     tvalid();
endinterface
(* always_ready, always_enabled *)
interface PciewrapPci_exp#(numeric type lanes);
    method Action      rxn(Bit#(lanes) v);
    method Action      rxp(Bit#(lanes) v);
    method Bit#(lanes)     txn();
    method Bit#(lanes)     txp();
endinterface
(* always_ready, always_enabled *)
interface PciewrapPcie_drp#(numeric type lanes);
    method Action      addr(Bit#(9) v);
    method Action      clk(Bit#(1) v);
    method Action      di(Bit#(16) v);
    method Bit#(16)     zzdo();
    method Action      en(Bit#(1) v);
    method Bit#(1)     rdy();
    method Action      we(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapPipe#(numeric type lanes);
    method Action      dclk_in(Bit#(1) v);
    method Bit#(1)     gen3_out();
    method Action      mmcm_lock_in(Bit#(1) v);
    method Action      mmcm_rst_n(Bit#(1) v);
    method Action      oobclk_in(Bit#(1) v);
    method Action      pclk_in(Bit#(1) v);
    method Bit#(lanes)     pclk_sel_out();
    method Action      rxoutclk_in(Bit#(lanes) v);
    method Bit#(lanes)     rxoutclk_out();
    method Action      rxusrclk_in(Bit#(1) v);
    method Bit#(1)     txoutclk_out();
    method Action      userclk1_in(Bit#(1) v);
    method Action      userclk2_in(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapPl#(numeric type lanes);
    method Bit#(1)     directed_change_done();
    method Action      directed_link_auton(Bit#(1) v);
    method Action      directed_link_change(Bit#(2) v);
    method Action      directed_link_speed(Bit#(1) v);
    method Action      directed_link_width(Bit#(2) v);
    method Action      downstream_deemph_source(Bit#(1) v);
    method Bit#(3)     initial_link_width();
    method Bit#(2)     lane_reversal_mode();
    method Bit#(6)     ltssm_state();
    method Bit#(1)     phy_lnk_up();
    method Bit#(1)     received_hot_rst();
    method Bit#(2)     rx_pm_state();
    method Bit#(1)     sel_lnk_rate();
    method Bit#(2)     sel_lnk_width();
    method Action      transmit_hot_rst(Bit#(1) v);
    method Bit#(3)     tx_pm_state();
    method Action      upstream_prefer_deemph(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapPl_link#(numeric type lanes);
    method Bit#(1)     gen2_cap();
    method Bit#(1)     partner_gen2_supported();
    method Bit#(1)     upcfg_cap();
endinterface
(* always_ready, always_enabled *)
interface PciewrapRx#(numeric type lanes);
    method Action      np_ok(Bit#(1) v);
    method Action      np_req(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapS_axis_tx#(numeric type lanes);
    method Action      tdata(Bit#(64) v);
    method Action      tkeep(Bit#(8) v);
    method Action      tlast(Bit#(1) v);
    method Bit#(1)     tready();
    method Action      tuser(Bit#(4) v);
    method Action      tvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapStartup#(numeric type lanes);
    method Bit#(1)     cfgclk();
    method Bit#(1)     cfgmclk();
    method Action      clk(Bit#(1) v);
    method Bit#(1)     eos();
    method Action      gsr(Bit#(1) v);
    method Action      gts(Bit#(1) v);
    method Action      keyclearb(Bit#(1) v);
    method Action      pack(Bit#(1) v);
    method Bit#(1)     preq();
    method Action      usrcclko(Bit#(1) v);
    method Action      usrcclkts(Bit#(1) v);
    method Action      usrdoneo(Bit#(1) v);
    method Action      usrdonets(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface PciewrapTx#(numeric type lanes);
    method Bit#(6)     buf_av();
    method Action      cfg_gnt(Bit#(1) v);
    method Bit#(1)     cfg_req();
    method Bit#(1)     err_drop();
endinterface
(* always_ready, always_enabled *)
interface PciewrapUser#(numeric type lanes);
    method Bit#(1)     app_rdy();
    interface Clock     clk_out;
    method Bit#(1)     lnk_up();
    method Reset     reset_out();
endinterface
(* always_ready, always_enabled *)
interface PcieWrap#(numeric type lanes);
    interface PciewrapCfg_aer#(lanes)     cfg_aer;
    interface PciewrapCfg#(lanes)     cfg;
    interface PciewrapCfg_ds#(lanes)     cfg_ds;
    interface PciewrapCfg_err#(lanes)     cfg_err;
    interface PciewrapCfg_interrupt#(lanes)     cfg_interrupt;
    interface PciewrapCfg_mgmt#(lanes)     cfg_mgmt;
    interface PciewrapCfg_msg#(lanes)     cfg_msg;
    interface PciewrapCfg_pm#(lanes)     cfg_pm;
    interface PciewrapCfg_pmcsr#(lanes)     cfg_pmcsr;
    interface PciewrapCfg_root_control#(lanes)     cfg_root_control;
    interface PciewrapFc#(lanes)     fc;
    interface PciewrapIcap#(lanes)     icap;
    interface PciewrapM_axis_rx#(lanes)     m_axis_rx;
    interface PciewrapPci_exp#(lanes)     pci_exp;
    interface PciewrapPcie_drp#(lanes)     pcie_drp;
    interface PciewrapPipe#(lanes)     pipe;
    interface PciewrapPl#(lanes)     pl;
    interface PciewrapPl_link#(lanes)     pl_link;
    interface PciewrapRx#(lanes)     rx;
    interface PciewrapS_axis_tx#(lanes)     s_axis_tx;
    interface PciewrapStartup#(lanes)     startup;
    interface PciewrapTx#(lanes)     tx;
    interface PciewrapUser#(lanes)     user;
endinterface
import "BVI" pcie_7x_0 =
module mkPcieWrap#(Clock sys_clk, Reset sys_clk_reset, Reset sys_rst_n)(PcieWrap#(lanes));
    let lanes = valueOf(lanes);
    default_clock clk();
    default_reset rst();
        input_clock sys_clk(sys_clk) = sys_clk;
        input_reset sys_clk_reset() = sys_clk_reset; /* from clock*/
        input_reset sys_rst_n(sys_rst_n) = sys_rst_n;
    interface PciewrapCfg_aer     cfg_aer;
        method cfg_aerecrc_check_en ecrc_check_en();
        method cfg_aerecrc_gen_en ecrc_gen_en();
        method interrupt_msgnum(cfg_aerinterrupt_msgnum) enable((*inhigh*) EN_cfg_aerinterrupt_msgnum);
        method cfg_aerrooterr_corr_err_received rooterr_corr_err_received();
        method cfg_aerrooterr_corr_err_reporting_en rooterr_corr_err_reporting_en();
        method cfg_aerrooterr_fatal_err_received rooterr_fatal_err_received();
        method cfg_aerrooterr_fatal_err_reporting_en rooterr_fatal_err_reporting_en();
        method cfg_aerrooterr_non_fatal_err_received rooterr_non_fatal_err_received();
        method cfg_aerrooterr_non_fatal_err_reporting_en rooterr_non_fatal_err_reporting_en();
    endinterface
    interface PciewrapCfg     cfg;
        method cfg_bridge_serr_en bridge_serr_en();
        method cfg_bus_number bus_number();
        method cfg_command command();
        method cfg_dcommand dcommand();
        method cfg_dcommand2 dcommand2();
        method cfg_device_number device_number();
        method cfg_function_number function_number();
        method interrupt(cfg_interrupt) enable((*inhigh*) EN_cfg_interrupt);
        method cfg_lcommand lcommand();
        method cfg_lstatus lstatus();
        method cfg_pcie_link_state pcie_link_state();
        method pciecap_interrupt_msgnum(cfg_pciecap_interrupt_msgnum) enable((*inhigh*) EN_cfg_pciecap_interrupt_msgnum);
        method cfg_received_func_lvl_rst received_func_lvl_rst();
        method cfg_slot_control_electromech_il_ctl_pulse slot_control_electromech_il_ctl_pulse();
        method cfg_status status();
        method cfg_to_turnoff to_turnoff();
        method trn_pending(cfg_trn_pending) enable((*inhigh*) EN_cfg_trn_pending);
        method turnoff_ok(cfg_turnoff_ok) enable((*inhigh*) EN_cfg_turnoff_ok);
        method cfg_vc_tcvc_map vc_tcvc_map();
    endinterface
    interface PciewrapCfg_ds     cfg_ds;
        method bus_number(cfg_dsbus_number) enable((*inhigh*) EN_cfg_dsbus_number);
        method device_number(cfg_dsdevice_number) enable((*inhigh*) EN_cfg_dsdevice_number);
        method function_number(cfg_dsfunction_number) enable((*inhigh*) EN_cfg_dsfunction_number);
        method n(cfg_dsn) enable((*inhigh*) EN_cfg_dsn);
        method cfg_dstatus tatus();
    endinterface
    interface PciewrapCfg_err     cfg_err;
        method acs(cfg_erracs) enable((*inhigh*) EN_cfg_erracs);
        method aer_headerlog(cfg_erraer_headerlog) enable((*inhigh*) EN_cfg_erraer_headerlog);
        method cfg_erraer_headerlog_set aer_headerlog_set();
        method atomic_egress_blocked(cfg_erratomic_egress_blocked) enable((*inhigh*) EN_cfg_erratomic_egress_blocked);
        method cor(cfg_errcor) enable((*inhigh*) EN_cfg_errcor);
        method cpl_abort(cfg_errcpl_abort) enable((*inhigh*) EN_cfg_errcpl_abort);
        method cfg_errcpl_rdy cpl_rdy();
        method cpl_timeout(cfg_errcpl_timeout) enable((*inhigh*) EN_cfg_errcpl_timeout);
        method cpl_unexpect(cfg_errcpl_unexpect) enable((*inhigh*) EN_cfg_errcpl_unexpect);
        method ecrc(cfg_errecrc) enable((*inhigh*) EN_cfg_errecrc);
        method internal_cor(cfg_errinternal_cor) enable((*inhigh*) EN_cfg_errinternal_cor);
        method internal_uncor(cfg_errinternal_uncor) enable((*inhigh*) EN_cfg_errinternal_uncor);
        method locked(cfg_errlocked) enable((*inhigh*) EN_cfg_errlocked);
        method malformed(cfg_errmalformed) enable((*inhigh*) EN_cfg_errmalformed);
        method mc_blocked(cfg_errmc_blocked) enable((*inhigh*) EN_cfg_errmc_blocked);
        method norecovery(cfg_errnorecovery) enable((*inhigh*) EN_cfg_errnorecovery);
        method poisoned(cfg_errpoisoned) enable((*inhigh*) EN_cfg_errpoisoned);
        method posted(cfg_errposted) enable((*inhigh*) EN_cfg_errposted);
        method tlp_cpl_header(cfg_errtlp_cpl_header) enable((*inhigh*) EN_cfg_errtlp_cpl_header);
        method ur(cfg_errur) enable((*inhigh*) EN_cfg_errur);
    endinterface
    interface PciewrapCfg_interrupt     cfg_interrupt;
        method zzassert(cfg_interruptassert) enable((*inhigh*) EN_cfg_interruptassert);
        method di(cfg_interruptdi) enable((*inhigh*) EN_cfg_interruptdi);
        method cfg_interruptdo zzdo();
        method cfg_interruptmmenable mmenable();
        method cfg_interruptmsienable msienable();
        method cfg_interruptmsixenable msixenable();
        method cfg_interruptmsixfm msixfm();
        method cfg_interruptrdy rdy();
        method stat(cfg_interruptstat) enable((*inhigh*) EN_cfg_interruptstat);
    endinterface
    interface PciewrapCfg_mgmt     cfg_mgmt;
        method byte_en(cfg_mgmtbyte_en) enable((*inhigh*) EN_cfg_mgmtbyte_en);
        method di(cfg_mgmtdi) enable((*inhigh*) EN_cfg_mgmtdi);
        method cfg_mgmtdo zzdo();
        method dwaddr(cfg_mgmtdwaddr) enable((*inhigh*) EN_cfg_mgmtdwaddr);
        method rd_en(cfg_mgmtrd_en) enable((*inhigh*) EN_cfg_mgmtrd_en);
        method cfg_mgmtrd_wr_done rd_wr_done();
        method wr_en(cfg_mgmtwr_en) enable((*inhigh*) EN_cfg_mgmtwr_en);
        method wr_readonly(cfg_mgmtwr_readonly) enable((*inhigh*) EN_cfg_mgmtwr_readonly);
        method wr_rw1c_as_rw(cfg_mgmtwr_rw1c_as_rw) enable((*inhigh*) EN_cfg_mgmtwr_rw1c_as_rw);
    endinterface
    interface PciewrapCfg_msg     cfg_msg;
        method cfg_msgdata data();
        method cfg_msgreceived received();
        method cfg_msgreceived_assert_int_a received_assert_int_a();
        method cfg_msgreceived_assert_int_b received_assert_int_b();
        method cfg_msgreceived_assert_int_c received_assert_int_c();
        method cfg_msgreceived_assert_int_d received_assert_int_d();
        method cfg_msgreceived_deassert_int_a received_deassert_int_a();
        method cfg_msgreceived_deassert_int_b received_deassert_int_b();
        method cfg_msgreceived_deassert_int_c received_deassert_int_c();
        method cfg_msgreceived_deassert_int_d received_deassert_int_d();
        method cfg_msgreceived_err_cor received_err_cor();
        method cfg_msgreceived_err_fatal received_err_fatal();
        method cfg_msgreceived_err_non_fatal received_err_non_fatal();
        method cfg_msgreceived_pm_as_nak received_pm_as_nak();
        method cfg_msgreceived_pm_pme received_pm_pme();
        method cfg_msgreceived_pme_to_ack received_pme_to_ack();
        method cfg_msgreceived_setslotpowerlimit received_setslotpowerlimit();
    endinterface
    interface PciewrapCfg_pm     cfg_pm;
        method force_state(cfg_pmforce_state) enable((*inhigh*) EN_cfg_pmforce_state);
        method force_state_en(cfg_pmforce_state_en) enable((*inhigh*) EN_cfg_pmforce_state_en);
        method halt_aspm_l0s(cfg_pmhalt_aspm_l0s) enable((*inhigh*) EN_cfg_pmhalt_aspm_l0s);
        method halt_aspm_l1(cfg_pmhalt_aspm_l1) enable((*inhigh*) EN_cfg_pmhalt_aspm_l1);
        method send_pme_to(cfg_pmsend_pme_to) enable((*inhigh*) EN_cfg_pmsend_pme_to);
        method wake(cfg_pmwake) enable((*inhigh*) EN_cfg_pmwake);
    endinterface
    interface PciewrapCfg_pmcsr     cfg_pmcsr;
        method cfg_pmcsrpme_en pme_en();
        method cfg_pmcsrpme_status pme_status();
        method cfg_pmcsrpowerstate powerstate();
    endinterface
    interface PciewrapCfg_root_control     cfg_root_control;
        method cfg_root_controlpme_int_en pme_int_en();
        method cfg_root_controlsyserr_corr_err_en syserr_corr_err_en();
        method cfg_root_controlsyserr_fatal_err_en syserr_fatal_err_en();
        method cfg_root_controlsyserr_non_fatal_err_en syserr_non_fatal_err_en();
    endinterface
    interface PciewrapFc     fc;
        method fc_cpld cpld();
        method fc_cplh cplh();
        method fc_npd npd();
        method fc_nph nph();
        method fc_pd pd();
        method fc_ph ph();
        method sel(fc_sel) enable((*inhigh*) EN_fc_sel);
    endinterface
    interface PciewrapIcap     icap;
        method clk(icap_clk) enable((*inhigh*) EN_icap_clk);
        method csib(icap_csib) enable((*inhigh*) EN_icap_csib);
        method i(icap_i) enable((*inhigh*) EN_icap_i);
        method icap_o o();
        method rdwrb(icap_rdwrb) enable((*inhigh*) EN_icap_rdwrb);
    endinterface
    interface PciewrapM_axis_rx     m_axis_rx;
        method m_axis_rx_tdata tdata();
        method m_axis_rx_tkeep tkeep();
        method m_axis_rx_tlast tlast();
        method tready(m_axis_rx_tready) enable((*inhigh*) EN_m_axis_rx_tready);
        method m_axis_rx_tuser tuser();
        method m_axis_rx_tvalid tvalid();
    endinterface
    interface PciewrapPci_exp     pci_exp;
        method rxn(pci_exprxn) enable((*inhigh*) EN_pci_exprxn) clocked_by (sys_clk) reset_by (sys_rst_n);
        method rxp(pci_exprxp) enable((*inhigh*) EN_pci_exprxp) clocked_by (sys_clk) reset_by (sys_rst_n);
        method pci_exptxn txn() clocked_by (sys_clk) reset_by (sys_rst_n);
        method pci_exptxp txp() clocked_by (sys_clk) reset_by (sys_rst_n);
    endinterface
    interface PciewrapPcie_drp     pcie_drp;
        method addr(pcie_drpaddr) enable((*inhigh*) EN_pcie_drpaddr);
        method clk(pcie_drpclk) enable((*inhigh*) EN_pcie_drpclk);
        method di(pcie_drpdi) enable((*inhigh*) EN_pcie_drpdi);
        method pcie_drpdo zzdo();
        method en(pcie_drpen) enable((*inhigh*) EN_pcie_drpen);
        method pcie_drprdy rdy();
        method we(pcie_drpwe) enable((*inhigh*) EN_pcie_drpwe);
    endinterface
    interface PciewrapPipe     pipe;
        method dclk_in(pipedclk_in) enable((*inhigh*) EN_pipedclk_in);
        method pipegen3_out gen3_out();
        method mmcm_lock_in(pipemmcm_lock_in) enable((*inhigh*) EN_pipemmcm_lock_in);
        method mmcm_rst_n(pipemmcm_rst_n) enable((*inhigh*) EN_pipemmcm_rst_n);
        method oobclk_in(pipeoobclk_in) enable((*inhigh*) EN_pipeoobclk_in);
        method pclk_in(pipepclk_in) enable((*inhigh*) EN_pipepclk_in);
        method pipepclk_sel_out pclk_sel_out();
        method rxoutclk_in(piperxoutclk_in) enable((*inhigh*) EN_piperxoutclk_in);
        method piperxoutclk_out rxoutclk_out();
        method rxusrclk_in(piperxusrclk_in) enable((*inhigh*) EN_piperxusrclk_in);
        method pipetxoutclk_out txoutclk_out();
        method userclk1_in(pipeuserclk1_in) enable((*inhigh*) EN_pipeuserclk1_in);
        method userclk2_in(pipeuserclk2_in) enable((*inhigh*) EN_pipeuserclk2_in);
    endinterface
    interface PciewrapPl     pl;
        method pl_directed_change_done directed_change_done();
        method directed_link_auton(pl_directed_link_auton) enable((*inhigh*) EN_pl_directed_link_auton);
        method directed_link_change(pl_directed_link_change) enable((*inhigh*) EN_pl_directed_link_change);
        method directed_link_speed(pl_directed_link_speed) enable((*inhigh*) EN_pl_directed_link_speed);
        method directed_link_width(pl_directed_link_width) enable((*inhigh*) EN_pl_directed_link_width);
        method downstream_deemph_source(pl_downstream_deemph_source) enable((*inhigh*) EN_pl_downstream_deemph_source);
        method pl_initial_link_width initial_link_width();
        method pl_lane_reversal_mode lane_reversal_mode();
        method pl_ltssm_state ltssm_state();
        method pl_phy_lnk_up phy_lnk_up();
        method pl_received_hot_rst received_hot_rst();
        method pl_rx_pm_state rx_pm_state();
        method pl_sel_lnk_rate sel_lnk_rate();
        method pl_sel_lnk_width sel_lnk_width();
        method transmit_hot_rst(pl_transmit_hot_rst) enable((*inhigh*) EN_pl_transmit_hot_rst);
        method pl_tx_pm_state tx_pm_state();
        method upstream_prefer_deemph(pl_upstream_prefer_deemph) enable((*inhigh*) EN_pl_upstream_prefer_deemph);
    endinterface
    interface PciewrapPl_link     pl_link;
        method pl_linkgen2_cap gen2_cap();
        method pl_linkpartner_gen2_supported partner_gen2_supported();
        method pl_linkupcfg_cap upcfg_cap();
    endinterface
    interface PciewrapRx     rx;
        method np_ok(rx_np_ok) enable((*inhigh*) EN_rx_np_ok);
        method np_req(rx_np_req) enable((*inhigh*) EN_rx_np_req);
    endinterface
    interface PciewrapS_axis_tx     s_axis_tx;
        method tdata(s_axis_tx_tdata) enable((*inhigh*) EN_s_axis_tx_tdata);
        method tkeep(s_axis_tx_tkeep) enable((*inhigh*) EN_s_axis_tx_tkeep);
        method tlast(s_axis_tx_tlast) enable((*inhigh*) EN_s_axis_tx_tlast);
        method s_axis_tx_tready tready();
        method tuser(s_axis_tx_tuser) enable((*inhigh*) EN_s_axis_tx_tuser);
        method tvalid(s_axis_tx_tvalid) enable((*inhigh*) EN_s_axis_tx_tvalid);
    endinterface
    interface PciewrapStartup     startup;
        method startup_cfgclk cfgclk();
        method startup_cfgmclk cfgmclk();
        method clk(startup_clk) enable((*inhigh*) EN_startup_clk);
        method startup_eos eos();
        method gsr(startup_gsr) enable((*inhigh*) EN_startup_gsr);
        method gts(startup_gts) enable((*inhigh*) EN_startup_gts);
        method keyclearb(startup_keyclearb) enable((*inhigh*) EN_startup_keyclearb);
        method pack(startup_pack) enable((*inhigh*) EN_startup_pack);
        method startup_preq preq();
        method usrcclko(startup_usrcclko) enable((*inhigh*) EN_startup_usrcclko);
        method usrcclkts(startup_usrcclkts) enable((*inhigh*) EN_startup_usrcclkts);
        method usrdoneo(startup_usrdoneo) enable((*inhigh*) EN_startup_usrdoneo);
        method usrdonets(startup_usrdonets) enable((*inhigh*) EN_startup_usrdonets);
    endinterface
    interface PciewrapTx     tx;
        method tx_buf_av buf_av();
        method cfg_gnt(tx_cfg_gnt) enable((*inhigh*) EN_tx_cfg_gnt);
        method tx_cfg_req cfg_req();
        method tx_err_drop err_drop();
    endinterface
    interface PciewrapUser     user;
        method user_app_rdy app_rdy();
        output_clock clk_out(user_clk_out);
        method user_lnk_up lnk_up();
        output_reset reset_out(user_reset_out);
    endinterface
    schedule (cfg_aer.ecrc_check_en, cfg_aer.ecrc_gen_en, cfg_aer.interrupt_msgnum, cfg_aer.rooterr_corr_err_received, cfg_aer.rooterr_corr_err_reporting_en, cfg_aer.rooterr_fatal_err_received, cfg_aer.rooterr_fatal_err_reporting_en, cfg_aer.rooterr_non_fatal_err_received, cfg_aer.rooterr_non_fatal_err_reporting_en, cfg.bridge_serr_en, cfg.bus_number, cfg.command, cfg.dcommand, cfg.dcommand2, cfg.device_number, cfg.function_number, cfg.interrupt, cfg.lcommand, cfg.lstatus, cfg.pcie_link_state, cfg.pciecap_interrupt_msgnum, cfg.received_func_lvl_rst, cfg.slot_control_electromech_il_ctl_pulse, cfg.status, cfg.to_turnoff, cfg.trn_pending, cfg.turnoff_ok, cfg.vc_tcvc_map, cfg_ds.bus_number, cfg_ds.device_number, cfg_ds.function_number, cfg_ds.n, cfg_ds.tatus, cfg_err.acs, cfg_err.aer_headerlog, cfg_err.aer_headerlog_set, cfg_err.atomic_egress_blocked, cfg_err.cor, cfg_err.cpl_abort, cfg_err.cpl_rdy, cfg_err.cpl_timeout, cfg_err.cpl_unexpect, cfg_err.ecrc, cfg_err.internal_cor, cfg_err.internal_uncor, cfg_err.locked, cfg_err.malformed, cfg_err.mc_blocked, cfg_err.norecovery, cfg_err.poisoned, cfg_err.posted, cfg_err.tlp_cpl_header, cfg_err.ur, cfg_interrupt.zzassert, cfg_interrupt.di, cfg_interrupt.zzdo, cfg_interrupt.mmenable, cfg_interrupt.msienable, cfg_interrupt.msixenable, cfg_interrupt.msixfm, cfg_interrupt.rdy, cfg_interrupt.stat, cfg_mgmt.byte_en, cfg_mgmt.di, cfg_mgmt.zzdo, cfg_mgmt.dwaddr, cfg_mgmt.rd_en, cfg_mgmt.rd_wr_done, cfg_mgmt.wr_en, cfg_mgmt.wr_readonly, cfg_mgmt.wr_rw1c_as_rw, cfg_msg.data, cfg_msg.received, cfg_msg.received_assert_int_a, cfg_msg.received_assert_int_b, cfg_msg.received_assert_int_c, cfg_msg.received_assert_int_d, cfg_msg.received_deassert_int_a, cfg_msg.received_deassert_int_b, cfg_msg.received_deassert_int_c, cfg_msg.received_deassert_int_d, cfg_msg.received_err_cor, cfg_msg.received_err_fatal, cfg_msg.received_err_non_fatal, cfg_msg.received_pm_as_nak, cfg_msg.received_pm_pme, cfg_msg.received_pme_to_ack, cfg_msg.received_setslotpowerlimit, cfg_pm.force_state, cfg_pm.force_state_en, cfg_pm.halt_aspm_l0s, cfg_pm.halt_aspm_l1, cfg_pm.send_pme_to, cfg_pm.wake, cfg_pmcsr.pme_en, cfg_pmcsr.pme_status, cfg_pmcsr.powerstate, cfg_root_control.pme_int_en, cfg_root_control.syserr_corr_err_en, cfg_root_control.syserr_fatal_err_en, cfg_root_control.syserr_non_fatal_err_en, fc.cpld, fc.cplh, fc.npd, fc.nph, fc.pd, fc.ph, fc.sel, icap.clk, icap.csib, icap.i, icap.o, icap.rdwrb, m_axis_rx.tdata, m_axis_rx.tkeep, m_axis_rx.tlast, m_axis_rx.tready, m_axis_rx.tuser, m_axis_rx.tvalid, pci_exp.rxn, pci_exp.rxp, pci_exp.txn, pci_exp.txp, pcie_drp.addr, pcie_drp.clk, pcie_drp.di, pcie_drp.zzdo, pcie_drp.en, pcie_drp.rdy, pcie_drp.we, pipe.dclk_in, pipe.gen3_out, pipe.mmcm_lock_in, pipe.mmcm_rst_n, pipe.oobclk_in, pipe.pclk_in, pipe.pclk_sel_out, pipe.rxoutclk_in, pipe.rxoutclk_out, pipe.rxusrclk_in, pipe.txoutclk_out, pipe.userclk1_in, pipe.userclk2_in, pl.directed_change_done, pl.directed_link_auton, pl.directed_link_change, pl.directed_link_speed, pl.directed_link_width, pl.downstream_deemph_source, pl.initial_link_width, pl.lane_reversal_mode, pl.ltssm_state, pl.phy_lnk_up, pl.received_hot_rst, pl.rx_pm_state, pl.sel_lnk_rate, pl.sel_lnk_width, pl.transmit_hot_rst, pl.tx_pm_state, pl.upstream_prefer_deemph, pl_link.gen2_cap, pl_link.partner_gen2_supported, pl_link.upcfg_cap, rx.np_ok, rx.np_req, s_axis_tx.tdata, s_axis_tx.tkeep, s_axis_tx.tlast, s_axis_tx.tready, s_axis_tx.tuser, s_axis_tx.tvalid, startup.cfgclk, startup.cfgmclk, startup.clk, startup.eos, startup.gsr, startup.gts, startup.keyclearb, startup.pack, startup.preq, startup.usrcclko, startup.usrcclkts, startup.usrdoneo, startup.usrdonets, tx.buf_av, tx.cfg_gnt, tx.cfg_req, tx.err_drop, user.app_rdy, user.lnk_up) CF (cfg_aer.ecrc_check_en, cfg_aer.ecrc_gen_en, cfg_aer.interrupt_msgnum, cfg_aer.rooterr_corr_err_received, cfg_aer.rooterr_corr_err_reporting_en, cfg_aer.rooterr_fatal_err_received, cfg_aer.rooterr_fatal_err_reporting_en, cfg_aer.rooterr_non_fatal_err_received, cfg_aer.rooterr_non_fatal_err_reporting_en, cfg.bridge_serr_en, cfg.bus_number, cfg.command, cfg.dcommand, cfg.dcommand2, cfg.device_number, cfg.function_number, cfg.interrupt, cfg.lcommand, cfg.lstatus, cfg.pcie_link_state, cfg.pciecap_interrupt_msgnum, cfg.received_func_lvl_rst, cfg.slot_control_electromech_il_ctl_pulse, cfg.status, cfg.to_turnoff, cfg.trn_pending, cfg.turnoff_ok, cfg.vc_tcvc_map, cfg_ds.bus_number, cfg_ds.device_number, cfg_ds.function_number, cfg_ds.n, cfg_ds.tatus, cfg_err.acs, cfg_err.aer_headerlog, cfg_err.aer_headerlog_set, cfg_err.atomic_egress_blocked, cfg_err.cor, cfg_err.cpl_abort, cfg_err.cpl_rdy, cfg_err.cpl_timeout, cfg_err.cpl_unexpect, cfg_err.ecrc, cfg_err.internal_cor, cfg_err.internal_uncor, cfg_err.locked, cfg_err.malformed, cfg_err.mc_blocked, cfg_err.norecovery, cfg_err.poisoned, cfg_err.posted, cfg_err.tlp_cpl_header, cfg_err.ur, cfg_interrupt.zzassert, cfg_interrupt.di, cfg_interrupt.zzdo, cfg_interrupt.mmenable, cfg_interrupt.msienable, cfg_interrupt.msixenable, cfg_interrupt.msixfm, cfg_interrupt.rdy, cfg_interrupt.stat, cfg_mgmt.byte_en, cfg_mgmt.di, cfg_mgmt.zzdo, cfg_mgmt.dwaddr, cfg_mgmt.rd_en, cfg_mgmt.rd_wr_done, cfg_mgmt.wr_en, cfg_mgmt.wr_readonly, cfg_mgmt.wr_rw1c_as_rw, cfg_msg.data, cfg_msg.received, cfg_msg.received_assert_int_a, cfg_msg.received_assert_int_b, cfg_msg.received_assert_int_c, cfg_msg.received_assert_int_d, cfg_msg.received_deassert_int_a, cfg_msg.received_deassert_int_b, cfg_msg.received_deassert_int_c, cfg_msg.received_deassert_int_d, cfg_msg.received_err_cor, cfg_msg.received_err_fatal, cfg_msg.received_err_non_fatal, cfg_msg.received_pm_as_nak, cfg_msg.received_pm_pme, cfg_msg.received_pme_to_ack, cfg_msg.received_setslotpowerlimit, cfg_pm.force_state, cfg_pm.force_state_en, cfg_pm.halt_aspm_l0s, cfg_pm.halt_aspm_l1, cfg_pm.send_pme_to, cfg_pm.wake, cfg_pmcsr.pme_en, cfg_pmcsr.pme_status, cfg_pmcsr.powerstate, cfg_root_control.pme_int_en, cfg_root_control.syserr_corr_err_en, cfg_root_control.syserr_fatal_err_en, cfg_root_control.syserr_non_fatal_err_en, fc.cpld, fc.cplh, fc.npd, fc.nph, fc.pd, fc.ph, fc.sel, icap.clk, icap.csib, icap.i, icap.o, icap.rdwrb, m_axis_rx.tdata, m_axis_rx.tkeep, m_axis_rx.tlast, m_axis_rx.tready, m_axis_rx.tuser, m_axis_rx.tvalid, pci_exp.rxn, pci_exp.rxp, pci_exp.txn, pci_exp.txp, pcie_drp.addr, pcie_drp.clk, pcie_drp.di, pcie_drp.zzdo, pcie_drp.en, pcie_drp.rdy, pcie_drp.we, pipe.dclk_in, pipe.gen3_out, pipe.mmcm_lock_in, pipe.mmcm_rst_n, pipe.oobclk_in, pipe.pclk_in, pipe.pclk_sel_out, pipe.rxoutclk_in, pipe.rxoutclk_out, pipe.rxusrclk_in, pipe.txoutclk_out, pipe.userclk1_in, pipe.userclk2_in, pl.directed_change_done, pl.directed_link_auton, pl.directed_link_change, pl.directed_link_speed, pl.directed_link_width, pl.downstream_deemph_source, pl.initial_link_width, pl.lane_reversal_mode, pl.ltssm_state, pl.phy_lnk_up, pl.received_hot_rst, pl.rx_pm_state, pl.sel_lnk_rate, pl.sel_lnk_width, pl.transmit_hot_rst, pl.tx_pm_state, pl.upstream_prefer_deemph, pl_link.gen2_cap, pl_link.partner_gen2_supported, pl_link.upcfg_cap, rx.np_ok, rx.np_req, s_axis_tx.tdata, s_axis_tx.tkeep, s_axis_tx.tlast, s_axis_tx.tready, s_axis_tx.tuser, s_axis_tx.tvalid, startup.cfgclk, startup.cfgmclk, startup.clk, startup.eos, startup.gsr, startup.gts, startup.keyclearb, startup.pack, startup.preq, startup.usrcclko, startup.usrcclkts, startup.usrdoneo, startup.usrdonets, tx.buf_av, tx.cfg_gnt, tx.cfg_req, tx.err_drop, user.app_rdy, user.lnk_up);
endmodule
