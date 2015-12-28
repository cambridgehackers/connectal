
/*
   ../scripts/importbvi.py
   -o
   PCIEWRAPPER2.bsv
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
   -n
   int_userclk1_out
   -n
   int_userclk2_out
   -n
   int_
   -c
   int_userclk1_out
   -c
   int_userclk2_out
   -c
   int_oobclk_out
   -c
   int_dclk_out
   -c
   int_pclk_out_slave
   -c
   int_pipe_rxuserclk_out
   -c
   int_qplloutclk_out
   -c
   int_qplloutrefclk_out
   -c
   int_rxoutclk_out
   -n
   user_clk_out
   -n
   user_reset_out
   -c
   user_clk_out
   -r
   user_reset_out
   -c
   sys_clk
   -r
   sys_rst_n
   -n
   cfg_dsn
   -n
   cfg_dstatus
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
   ../../out/vc707/pcie2_7x_0/pcie2_7x_0_stub.v
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
interface PciewrapM_axis_rx#(numeric type lanes);
    method Bit#(128)     tdata();
    method Bit#(16)     tkeep();
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
    method Bit#(1)     upcfg_cap();
endinterface
(* always_ready, always_enabled *)
interface PciewrapRx#(numeric type lanes);
    method Action      np_ok(Bit#(1) v);
    method Action      np_req(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapS_axis_tx#(numeric type lanes);
    method Action      tdata(Bit#(128) v);
    method Action      tkeep(Bit#(16) v);
    method Action      tlast(Bit#(1) v);
    method Bit#(1)     tready();
    method Action      tuser(Bit#(4) v);
    method Action      tvalid(Bit#(1) v);
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
    method Bit#(1)     lnk_up();
endinterface
(* always_ready, always_enabled *)
interface PcieWrap#(numeric type lanes);
    interface PciewrapCfg_aer#(lanes)     cfg_aer;
    interface PciewrapCfg#(lanes)     cfg;
    interface PciewrapCfg_ds#(lanes)     cfg_ds;
    method Action      cfg_dsn(Bit#(64) v);
    method Bit#(16)     cfg_dstatus();
    interface PciewrapCfg_err#(lanes)     cfg_err;
    interface PciewrapCfg_interrupt#(lanes)     cfg_interrupt;
    interface PciewrapCfg_mgmt#(lanes)     cfg_mgmt;
    method Action      cfg_mgmt_wr_rw1c_as_rw(Bit#(1) v);
    interface PciewrapCfg_msg#(lanes)     cfg_msg;
    interface PciewrapCfg_pm#(lanes)     cfg_pm;
    interface PciewrapCfg_pmcsr#(lanes)     cfg_pmcsr;
    interface PciewrapCfg_root_control#(lanes)     cfg_root_control;
    interface PciewrapFc#(lanes)     fc;
    interface Clock     int_dclk_out;
    method Bit#(1)     int_mmcm_lock_out();
    interface Clock     int_oobclk_out;
    interface Clock     int_pclk_out_slave;
    method Action      int_pclk_sel_slave(Bit#(8) v);
    method Bit#(1)     int_pipe_rxusrclk_out();
    method Bit#(2)     int_qplllock_out();
    interface Clock     int_qplloutclk_out;
    interface Clock     int_qplloutrefclk_out;
    interface Clock     int_rxoutclk_out;
    interface Clock     int_userclk1_out;
    interface Clock     int_userclk2_out;
    interface PciewrapM_axis_rx#(lanes)     m_axis_rx;
    interface PciewrapPci_exp#(lanes)     pci_exp;
    interface PciewrapPl#(lanes)     pl;
    method Bit#(1)     pl_link_gen2_cap();
    method Bit#(1)     pl_link_partner_gen2_supported();
    interface PciewrapPl_link#(lanes)     pl_link;
    interface PciewrapRx#(lanes)     rx;
    interface PciewrapS_axis_tx#(lanes)     s_axis_tx;
    interface PciewrapTx#(lanes)     tx;
    interface PciewrapUser#(lanes)     user;
    interface Clock     user_clk_out;
    method Reset     user_reset_out();
endinterface
import "BVI" pcie2_7x_0 =
module mkPcieWrap#(Clock sys_clk, Reset sys_rst_n)(PcieWrap#(lanes));
    let lanes = valueOf(lanes);
    output_clock user_clk_out(user_clk_out);
    output_reset user_reset_out(user_reset_out);
        default_clock sys_clk(sys_clk) = sys_clk;
         /* from clock*/
        default_reset sys_rst_n(sys_rst_n) = sys_rst_n;
    interface PciewrapCfg_aer     cfg_aer;
        method cfg_aer_ecrc_check_en ecrc_check_en() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_aer_ecrc_gen_en ecrc_gen_en() clocked_by (user_clk_out) reset_by (user_reset_out);
        method interrupt_msgnum(cfg_aer_interrupt_msgnum) enable((*inhigh*) EN_cfg_aer_interrupt_msgnum) clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_aer_rooterr_corr_err_received rooterr_corr_err_received() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_aer_rooterr_corr_err_reporting_en rooterr_corr_err_reporting_en() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_aer_rooterr_fatal_err_received rooterr_fatal_err_received() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_aer_rooterr_fatal_err_reporting_en rooterr_fatal_err_reporting_en() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_aer_rooterr_non_fatal_err_received rooterr_non_fatal_err_received() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_aer_rooterr_non_fatal_err_reporting_en rooterr_non_fatal_err_reporting_en() clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    interface PciewrapCfg     cfg;
        method cfg_bridge_serr_en bridge_serr_en() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_bus_number bus_number() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_command command() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_dcommand dcommand() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_dcommand2 dcommand2() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_device_number device_number() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_function_number function_number() clocked_by (user_clk_out) reset_by (user_reset_out);
        method interrupt(cfg_interrupt) enable((*inhigh*) EN_cfg_interrupt) clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_lcommand lcommand() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_lstatus lstatus() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_pcie_link_state pcie_link_state() clocked_by (user_clk_out) reset_by (user_reset_out);
        method pciecap_interrupt_msgnum(cfg_pciecap_interrupt_msgnum) enable((*inhigh*) EN_cfg_pciecap_interrupt_msgnum) clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_received_func_lvl_rst received_func_lvl_rst() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_slot_control_electromech_il_ctl_pulse slot_control_electromech_il_ctl_pulse() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_status status() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_to_turnoff to_turnoff() clocked_by (user_clk_out) reset_by (user_reset_out);
        method trn_pending(cfg_trn_pending) enable((*inhigh*) EN_cfg_trn_pending) clocked_by (user_clk_out) reset_by (user_reset_out);
        method turnoff_ok(cfg_turnoff_ok) enable((*inhigh*) EN_cfg_turnoff_ok) clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_vc_tcvc_map vc_tcvc_map() clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    interface PciewrapCfg_ds     cfg_ds;
        method bus_number(cfg_ds_bus_number) enable((*inhigh*) EN_cfg_ds_bus_number) clocked_by (user_clk_out) reset_by (user_reset_out);
        method device_number(cfg_ds_device_number) enable((*inhigh*) EN_cfg_ds_device_number) clocked_by (user_clk_out) reset_by (user_reset_out);
        method function_number(cfg_ds_function_number) enable((*inhigh*) EN_cfg_ds_function_number) clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    method cfg_dsn(cfg_dsn) enable((*inhigh*) EN_cfg_dsn) clocked_by (user_clk_out) reset_by (user_reset_out);
    method cfg_dstatus cfg_dstatus() clocked_by (user_clk_out) reset_by (user_reset_out);
    interface PciewrapCfg_err     cfg_err;
        method acs(cfg_err_acs) enable((*inhigh*) EN_cfg_err_acs) clocked_by (user_clk_out) reset_by (user_reset_out);
        method aer_headerlog(cfg_err_aer_headerlog) enable((*inhigh*) EN_cfg_err_aer_headerlog) clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_err_aer_headerlog_set aer_headerlog_set() clocked_by (user_clk_out) reset_by (user_reset_out);
        method atomic_egress_blocked(cfg_err_atomic_egress_blocked) enable((*inhigh*) EN_cfg_err_atomic_egress_blocked) clocked_by (user_clk_out) reset_by (user_reset_out);
        method cor(cfg_err_cor) enable((*inhigh*) EN_cfg_err_cor) clocked_by (user_clk_out) reset_by (user_reset_out);
        method cpl_abort(cfg_err_cpl_abort) enable((*inhigh*) EN_cfg_err_cpl_abort) clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_err_cpl_rdy cpl_rdy() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cpl_timeout(cfg_err_cpl_timeout) enable((*inhigh*) EN_cfg_err_cpl_timeout) clocked_by (user_clk_out) reset_by (user_reset_out);
        method cpl_unexpect(cfg_err_cpl_unexpect) enable((*inhigh*) EN_cfg_err_cpl_unexpect) clocked_by (user_clk_out) reset_by (user_reset_out);
        method ecrc(cfg_err_ecrc) enable((*inhigh*) EN_cfg_err_ecrc) clocked_by (user_clk_out) reset_by (user_reset_out);
        method internal_cor(cfg_err_internal_cor) enable((*inhigh*) EN_cfg_err_internal_cor) clocked_by (user_clk_out) reset_by (user_reset_out);
        method internal_uncor(cfg_err_internal_uncor) enable((*inhigh*) EN_cfg_err_internal_uncor) clocked_by (user_clk_out) reset_by (user_reset_out);
        method locked(cfg_err_locked) enable((*inhigh*) EN_cfg_err_locked) clocked_by (user_clk_out) reset_by (user_reset_out);
        method malformed(cfg_err_malformed) enable((*inhigh*) EN_cfg_err_malformed) clocked_by (user_clk_out) reset_by (user_reset_out);
        method mc_blocked(cfg_err_mc_blocked) enable((*inhigh*) EN_cfg_err_mc_blocked) clocked_by (user_clk_out) reset_by (user_reset_out);
        method norecovery(cfg_err_norecovery) enable((*inhigh*) EN_cfg_err_norecovery) clocked_by (user_clk_out) reset_by (user_reset_out);
        method poisoned(cfg_err_poisoned) enable((*inhigh*) EN_cfg_err_poisoned) clocked_by (user_clk_out) reset_by (user_reset_out);
        method posted(cfg_err_posted) enable((*inhigh*) EN_cfg_err_posted) clocked_by (user_clk_out) reset_by (user_reset_out);
        method tlp_cpl_header(cfg_err_tlp_cpl_header) enable((*inhigh*) EN_cfg_err_tlp_cpl_header) clocked_by (user_clk_out) reset_by (user_reset_out);
        method ur(cfg_err_ur) enable((*inhigh*) EN_cfg_err_ur) clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    interface PciewrapCfg_interrupt     cfg_interrupt;
        method zzassert(cfg_interrupt_assert) enable((*inhigh*) EN_cfg_interrupt_assert) clocked_by (user_clk_out) reset_by (user_reset_out);
        method di(cfg_interrupt_di) enable((*inhigh*) EN_cfg_interrupt_di) clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_interrupt_do zzdo() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_interrupt_mmenable mmenable() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_interrupt_msienable msienable() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_interrupt_msixenable msixenable() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_interrupt_msixfm msixfm() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_interrupt_rdy rdy() clocked_by (user_clk_out) reset_by (user_reset_out);
        method stat(cfg_interrupt_stat) enable((*inhigh*) EN_cfg_interrupt_stat) clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    interface PciewrapCfg_mgmt     cfg_mgmt;
        method byte_en(cfg_mgmt_byte_en) enable((*inhigh*) EN_cfg_mgmt_byte_en) clocked_by (user_clk_out) reset_by (user_reset_out);
        method di(cfg_mgmt_di) enable((*inhigh*) EN_cfg_mgmt_di) clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_mgmt_do zzdo() clocked_by (user_clk_out) reset_by (user_reset_out);
        method dwaddr(cfg_mgmt_dwaddr) enable((*inhigh*) EN_cfg_mgmt_dwaddr) clocked_by (user_clk_out) reset_by (user_reset_out);
        method rd_en(cfg_mgmt_rd_en) enable((*inhigh*) EN_cfg_mgmt_rd_en) clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_mgmt_rd_wr_done rd_wr_done() clocked_by (user_clk_out) reset_by (user_reset_out);
        method wr_en(cfg_mgmt_wr_en) enable((*inhigh*) EN_cfg_mgmt_wr_en) clocked_by (user_clk_out) reset_by (user_reset_out);
        method wr_readonly(cfg_mgmt_wr_readonly) enable((*inhigh*) EN_cfg_mgmt_wr_readonly) clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    method cfg_mgmt_wr_rw1c_as_rw(cfg_mgmt_wr_rw1c_as_rw) enable((*inhigh*) EN_cfg_mgmt_wr_rw1c_as_rw) clocked_by (user_clk_out) reset_by (user_reset_out);
    interface PciewrapCfg_msg     cfg_msg;
        method cfg_msg_data data() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_msg_received received() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_msg_received_assert_int_a received_assert_int_a() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_msg_received_assert_int_b received_assert_int_b() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_msg_received_assert_int_c received_assert_int_c() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_msg_received_assert_int_d received_assert_int_d() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_msg_received_deassert_int_a received_deassert_int_a() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_msg_received_deassert_int_b received_deassert_int_b() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_msg_received_deassert_int_c received_deassert_int_c() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_msg_received_deassert_int_d received_deassert_int_d() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_msg_received_err_cor received_err_cor() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_msg_received_err_fatal received_err_fatal() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_msg_received_err_non_fatal received_err_non_fatal() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_msg_received_pm_as_nak received_pm_as_nak() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_msg_received_pm_pme received_pm_pme() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_msg_received_pme_to_ack received_pme_to_ack() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_msg_received_setslotpowerlimit received_setslotpowerlimit() clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    interface PciewrapCfg_pm     cfg_pm;
        method force_state(cfg_pm_force_state) enable((*inhigh*) EN_cfg_pm_force_state) clocked_by (user_clk_out) reset_by (user_reset_out);
        method force_state_en(cfg_pm_force_state_en) enable((*inhigh*) EN_cfg_pm_force_state_en) clocked_by (user_clk_out) reset_by (user_reset_out);
        method halt_aspm_l0s(cfg_pm_halt_aspm_l0s) enable((*inhigh*) EN_cfg_pm_halt_aspm_l0s) clocked_by (user_clk_out) reset_by (user_reset_out);
        method halt_aspm_l1(cfg_pm_halt_aspm_l1) enable((*inhigh*) EN_cfg_pm_halt_aspm_l1) clocked_by (user_clk_out) reset_by (user_reset_out);
        method send_pme_to(cfg_pm_send_pme_to) enable((*inhigh*) EN_cfg_pm_send_pme_to) clocked_by (user_clk_out) reset_by (user_reset_out);
        method wake(cfg_pm_wake) enable((*inhigh*) EN_cfg_pm_wake) clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    interface PciewrapCfg_pmcsr     cfg_pmcsr;
        method cfg_pmcsr_pme_en pme_en() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_pmcsr_pme_status pme_status() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_pmcsr_powerstate powerstate() clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    interface PciewrapCfg_root_control     cfg_root_control;
        method cfg_root_control_pme_int_en pme_int_en() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_root_control_syserr_corr_err_en syserr_corr_err_en() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_root_control_syserr_fatal_err_en syserr_fatal_err_en() clocked_by (user_clk_out) reset_by (user_reset_out);
        method cfg_root_control_syserr_non_fatal_err_en syserr_non_fatal_err_en() clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    interface PciewrapFc     fc;
        method fc_cpld cpld() clocked_by (user_clk_out) reset_by (user_reset_out);
        method fc_cplh cplh() clocked_by (user_clk_out) reset_by (user_reset_out);
        method fc_npd npd() clocked_by (user_clk_out) reset_by (user_reset_out);
        method fc_nph nph() clocked_by (user_clk_out) reset_by (user_reset_out);
        method fc_pd pd() clocked_by (user_clk_out) reset_by (user_reset_out);
        method fc_ph ph() clocked_by (user_clk_out) reset_by (user_reset_out);
        method sel(fc_sel) enable((*inhigh*) EN_fc_sel) clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    output_clock int_dclk_out(int_dclk_out);
    method int_mmcm_lock_out int_mmcm_lock_out();
    output_clock int_oobclk_out(int_oobclk_out);
    output_clock int_pclk_out_slave(int_pclk_out_slave);
    method int_pclk_sel_slave(int_pclk_sel_slave) enable((*inhigh*) EN_int_pclk_sel_slave) clocked_by (user_clk_out) reset_by (user_reset_out);
    method int_pipe_rxusrclk_out int_pipe_rxusrclk_out();
    method int_qplllock_out int_qplllock_out();
    output_clock int_qplloutclk_out(int_qplloutclk_out);
    output_clock int_qplloutrefclk_out(int_qplloutrefclk_out);
    output_clock int_rxoutclk_out(int_rxoutclk_out);
    output_clock int_userclk1_out(int_userclk1_out);
    output_clock int_userclk2_out(int_userclk2_out);
    interface PciewrapM_axis_rx     m_axis_rx;
        method m_axis_rx_tdata tdata() clocked_by (user_clk_out) reset_by (user_reset_out);
        method m_axis_rx_tkeep tkeep() clocked_by (user_clk_out) reset_by (user_reset_out);
        method m_axis_rx_tlast tlast() clocked_by (user_clk_out) reset_by (user_reset_out);
        method tready(m_axis_rx_tready) enable((*inhigh*) EN_m_axis_rx_tready) clocked_by (user_clk_out) reset_by (user_reset_out);
        method m_axis_rx_tuser tuser() clocked_by (user_clk_out) reset_by (user_reset_out);
        method m_axis_rx_tvalid tvalid() clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    interface PciewrapPci_exp     pci_exp;
        method rxn(pci_exp_rxn) enable((*inhigh*) EN_pci_exp_rxn)  clocked_by (sys_clk) reset_by (sys_rst_n);
        method rxp(pci_exp_rxp) enable((*inhigh*) EN_pci_exp_rxp)  clocked_by (sys_clk) reset_by (sys_rst_n);
        method pci_exp_txn txn() clocked_by (sys_clk) reset_by (sys_rst_n);
        method pci_exp_txp txp() clocked_by (sys_clk) reset_by (sys_rst_n);
    endinterface
    interface PciewrapPl     pl;
        method pl_directed_change_done directed_change_done() clocked_by (user_clk_out) reset_by (user_reset_out);
        method directed_link_auton(pl_directed_link_auton) enable((*inhigh*) EN_pl_directed_link_auton) clocked_by (user_clk_out) reset_by (user_reset_out);
        method directed_link_change(pl_directed_link_change) enable((*inhigh*) EN_pl_directed_link_change) clocked_by (user_clk_out) reset_by (user_reset_out);
        method directed_link_speed(pl_directed_link_speed) enable((*inhigh*) EN_pl_directed_link_speed) clocked_by (user_clk_out) reset_by (user_reset_out);
        method directed_link_width(pl_directed_link_width) enable((*inhigh*) EN_pl_directed_link_width) clocked_by (user_clk_out) reset_by (user_reset_out);
        method downstream_deemph_source(pl_downstream_deemph_source) enable((*inhigh*) EN_pl_downstream_deemph_source) clocked_by (user_clk_out) reset_by (user_reset_out);
        method pl_initial_link_width initial_link_width() clocked_by (user_clk_out) reset_by (user_reset_out);
        method pl_lane_reversal_mode lane_reversal_mode() clocked_by (user_clk_out) reset_by (user_reset_out);
        method pl_ltssm_state ltssm_state() clocked_by (user_clk_out) reset_by (user_reset_out);
        method pl_phy_lnk_up phy_lnk_up() clocked_by (user_clk_out) reset_by (user_reset_out);
        method pl_received_hot_rst received_hot_rst() clocked_by (user_clk_out) reset_by (user_reset_out);
        method pl_rx_pm_state rx_pm_state() clocked_by (user_clk_out) reset_by (user_reset_out);
        method pl_sel_lnk_rate sel_lnk_rate() clocked_by (user_clk_out) reset_by (user_reset_out);
        method pl_sel_lnk_width sel_lnk_width() clocked_by (user_clk_out) reset_by (user_reset_out);
        method transmit_hot_rst(pl_transmit_hot_rst) enable((*inhigh*) EN_pl_transmit_hot_rst) clocked_by (user_clk_out) reset_by (user_reset_out);
        method pl_tx_pm_state tx_pm_state() clocked_by (user_clk_out) reset_by (user_reset_out);
        method upstream_prefer_deemph(pl_upstream_prefer_deemph) enable((*inhigh*) EN_pl_upstream_prefer_deemph) clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    method pl_link_gen2_cap pl_link_gen2_cap() clocked_by (user_clk_out) reset_by (user_reset_out);
    method pl_link_partner_gen2_supported pl_link_partner_gen2_supported() clocked_by (user_clk_out) reset_by (user_reset_out);
    interface PciewrapPl_link     pl_link;
        method pl_link_upcfg_cap upcfg_cap() clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    interface PciewrapRx     rx;
        method np_ok(rx_np_ok) enable((*inhigh*) EN_rx_np_ok) clocked_by (user_clk_out) reset_by (user_reset_out);
        method np_req(rx_np_req) enable((*inhigh*) EN_rx_np_req) clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    interface PciewrapS_axis_tx     s_axis_tx;
        method tdata(s_axis_tx_tdata) enable((*inhigh*) EN_s_axis_tx_tdata) clocked_by (user_clk_out) reset_by (user_reset_out);
        method tkeep(s_axis_tx_tkeep) enable((*inhigh*) EN_s_axis_tx_tkeep) clocked_by (user_clk_out) reset_by (user_reset_out);
        method tlast(s_axis_tx_tlast) enable((*inhigh*) EN_s_axis_tx_tlast) clocked_by (user_clk_out) reset_by (user_reset_out);
        method s_axis_tx_tready tready() clocked_by (user_clk_out) reset_by (user_reset_out);
        method tuser(s_axis_tx_tuser) enable((*inhigh*) EN_s_axis_tx_tuser) clocked_by (user_clk_out) reset_by (user_reset_out);
        method tvalid(s_axis_tx_tvalid) enable((*inhigh*) EN_s_axis_tx_tvalid) clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    interface PciewrapTx     tx;
        method tx_buf_av buf_av();
        method cfg_gnt(tx_cfg_gnt) enable((*inhigh*) EN_tx_cfg_gnt) clocked_by (user_clk_out) reset_by (user_reset_out);
        method tx_cfg_req cfg_req();
        method tx_err_drop err_drop();
    endinterface
    interface PciewrapUser     user;
        method user_app_rdy app_rdy() clocked_by (user_clk_out) reset_by (user_reset_out);
        method user_lnk_up lnk_up() clocked_by (user_clk_out) reset_by (user_reset_out);
    endinterface
    
    
    schedule (cfg_aer.ecrc_check_en, cfg_aer.ecrc_gen_en, cfg_aer.interrupt_msgnum, cfg_aer.rooterr_corr_err_received, cfg_aer.rooterr_corr_err_reporting_en, cfg_aer.rooterr_fatal_err_received, cfg_aer.rooterr_fatal_err_reporting_en, cfg_aer.rooterr_non_fatal_err_received, cfg_aer.rooterr_non_fatal_err_reporting_en, cfg.bridge_serr_en, cfg.bus_number, cfg.command, cfg.dcommand, cfg.dcommand2, cfg.device_number, cfg.function_number, cfg.interrupt, cfg.lcommand, cfg.lstatus, cfg.pcie_link_state, cfg.pciecap_interrupt_msgnum, cfg.received_func_lvl_rst, cfg.slot_control_electromech_il_ctl_pulse, cfg.status, cfg.to_turnoff, cfg.trn_pending, cfg.turnoff_ok, cfg.vc_tcvc_map, cfg_ds.bus_number, cfg_ds.device_number, cfg_ds.function_number, cfg_dsn, cfg_dstatus, cfg_err.acs, cfg_err.aer_headerlog, cfg_err.aer_headerlog_set, cfg_err.atomic_egress_blocked, cfg_err.cor, cfg_err.cpl_abort, cfg_err.cpl_rdy, cfg_err.cpl_timeout, cfg_err.cpl_unexpect, cfg_err.ecrc, cfg_err.internal_cor, cfg_err.internal_uncor, cfg_err.locked, cfg_err.malformed, cfg_err.mc_blocked, cfg_err.norecovery, cfg_err.poisoned, cfg_err.posted, cfg_err.tlp_cpl_header, cfg_err.ur, cfg_interrupt.zzassert, cfg_interrupt.di, cfg_interrupt.zzdo, cfg_interrupt.mmenable, cfg_interrupt.msienable, cfg_interrupt.msixenable, cfg_interrupt.msixfm, cfg_interrupt.rdy, cfg_interrupt.stat, cfg_mgmt.byte_en, cfg_mgmt.di, cfg_mgmt.zzdo, cfg_mgmt.dwaddr, cfg_mgmt.rd_en, cfg_mgmt.rd_wr_done, cfg_mgmt.wr_en, cfg_mgmt.wr_readonly, cfg_mgmt_wr_rw1c_as_rw, cfg_msg.data, cfg_msg.received, cfg_msg.received_assert_int_a, cfg_msg.received_assert_int_b, cfg_msg.received_assert_int_c, cfg_msg.received_assert_int_d, cfg_msg.received_deassert_int_a, cfg_msg.received_deassert_int_b, cfg_msg.received_deassert_int_c, cfg_msg.received_deassert_int_d, cfg_msg.received_err_cor, cfg_msg.received_err_fatal, cfg_msg.received_err_non_fatal, cfg_msg.received_pm_as_nak, cfg_msg.received_pm_pme, cfg_msg.received_pme_to_ack, cfg_msg.received_setslotpowerlimit, cfg_pm.force_state, cfg_pm.force_state_en, cfg_pm.halt_aspm_l0s, cfg_pm.halt_aspm_l1, cfg_pm.send_pme_to, cfg_pm.wake, cfg_pmcsr.pme_en, cfg_pmcsr.pme_status, cfg_pmcsr.powerstate, cfg_root_control.pme_int_en, cfg_root_control.syserr_corr_err_en, cfg_root_control.syserr_fatal_err_en, cfg_root_control.syserr_non_fatal_err_en, fc.cpld, fc.cplh, fc.npd, fc.nph, fc.pd, fc.ph, fc.sel, int_mmcm_lock_out, int_pclk_sel_slave, int_pipe_rxusrclk_out, int_qplllock_out, m_axis_rx.tdata, m_axis_rx.tkeep, m_axis_rx.tlast, m_axis_rx.tready, m_axis_rx.tuser, m_axis_rx.tvalid, pci_exp.rxn, pci_exp.rxp, pci_exp.txn, pci_exp.txp, pl.directed_change_done, pl.directed_link_auton, pl.directed_link_change, pl.directed_link_speed, pl.directed_link_width, pl.downstream_deemph_source, pl.initial_link_width, pl.lane_reversal_mode, pl.ltssm_state, pl.phy_lnk_up, pl.received_hot_rst, pl.rx_pm_state, pl.sel_lnk_rate, pl.sel_lnk_width, pl.transmit_hot_rst, pl.tx_pm_state, pl.upstream_prefer_deemph, pl_link_gen2_cap, pl_link_partner_gen2_supported, pl_link.upcfg_cap, rx.np_ok, rx.np_req, s_axis_tx.tdata, s_axis_tx.tkeep, s_axis_tx.tlast, s_axis_tx.tready, s_axis_tx.tuser, s_axis_tx.tvalid, tx.buf_av, tx.cfg_gnt, tx.cfg_req, tx.err_drop, user.app_rdy, user.lnk_up) CF (cfg_aer.ecrc_check_en, cfg_aer.ecrc_gen_en, cfg_aer.interrupt_msgnum, cfg_aer.rooterr_corr_err_received, cfg_aer.rooterr_corr_err_reporting_en, cfg_aer.rooterr_fatal_err_received, cfg_aer.rooterr_fatal_err_reporting_en, cfg_aer.rooterr_non_fatal_err_received, cfg_aer.rooterr_non_fatal_err_reporting_en, cfg.bridge_serr_en, cfg.bus_number, cfg.command, cfg.dcommand, cfg.dcommand2, cfg.device_number, cfg.function_number, cfg.interrupt, cfg.lcommand, cfg.lstatus, cfg.pcie_link_state, cfg.pciecap_interrupt_msgnum, cfg.received_func_lvl_rst, cfg.slot_control_electromech_il_ctl_pulse, cfg.status, cfg.to_turnoff, cfg.trn_pending, cfg.turnoff_ok, cfg.vc_tcvc_map, cfg_ds.bus_number, cfg_ds.device_number, cfg_ds.function_number, cfg_dsn, cfg_dstatus, cfg_err.acs, cfg_err.aer_headerlog, cfg_err.aer_headerlog_set, cfg_err.atomic_egress_blocked, cfg_err.cor, cfg_err.cpl_abort, cfg_err.cpl_rdy, cfg_err.cpl_timeout, cfg_err.cpl_unexpect, cfg_err.ecrc, cfg_err.internal_cor, cfg_err.internal_uncor, cfg_err.locked, cfg_err.malformed, cfg_err.mc_blocked, cfg_err.norecovery, cfg_err.poisoned, cfg_err.posted, cfg_err.tlp_cpl_header, cfg_err.ur, cfg_interrupt.zzassert, cfg_interrupt.di, cfg_interrupt.zzdo, cfg_interrupt.mmenable, cfg_interrupt.msienable, cfg_interrupt.msixenable, cfg_interrupt.msixfm, cfg_interrupt.rdy, cfg_interrupt.stat, cfg_mgmt.byte_en, cfg_mgmt.di, cfg_mgmt.zzdo, cfg_mgmt.dwaddr, cfg_mgmt.rd_en, cfg_mgmt.rd_wr_done, cfg_mgmt.wr_en, cfg_mgmt.wr_readonly, cfg_mgmt_wr_rw1c_as_rw, cfg_msg.data, cfg_msg.received, cfg_msg.received_assert_int_a, cfg_msg.received_assert_int_b, cfg_msg.received_assert_int_c, cfg_msg.received_assert_int_d, cfg_msg.received_deassert_int_a, cfg_msg.received_deassert_int_b, cfg_msg.received_deassert_int_c, cfg_msg.received_deassert_int_d, cfg_msg.received_err_cor, cfg_msg.received_err_fatal, cfg_msg.received_err_non_fatal, cfg_msg.received_pm_as_nak, cfg_msg.received_pm_pme, cfg_msg.received_pme_to_ack, cfg_msg.received_setslotpowerlimit, cfg_pm.force_state, cfg_pm.force_state_en, cfg_pm.halt_aspm_l0s, cfg_pm.halt_aspm_l1, cfg_pm.send_pme_to, cfg_pm.wake, cfg_pmcsr.pme_en, cfg_pmcsr.pme_status, cfg_pmcsr.powerstate, cfg_root_control.pme_int_en, cfg_root_control.syserr_corr_err_en, cfg_root_control.syserr_fatal_err_en, cfg_root_control.syserr_non_fatal_err_en, fc.cpld, fc.cplh, fc.npd, fc.nph, fc.pd, fc.ph, fc.sel, int_mmcm_lock_out, int_pclk_sel_slave, int_pipe_rxusrclk_out, int_qplllock_out, m_axis_rx.tdata, m_axis_rx.tkeep, m_axis_rx.tlast, m_axis_rx.tready, m_axis_rx.tuser, m_axis_rx.tvalid, pci_exp.rxn, pci_exp.rxp, pci_exp.txn, pci_exp.txp, pl.directed_change_done, pl.directed_link_auton, pl.directed_link_change, pl.directed_link_speed, pl.directed_link_width, pl.downstream_deemph_source, pl.initial_link_width, pl.lane_reversal_mode, pl.ltssm_state, pl.phy_lnk_up, pl.received_hot_rst, pl.rx_pm_state, pl.sel_lnk_rate, pl.sel_lnk_width, pl.transmit_hot_rst, pl.tx_pm_state, pl.upstream_prefer_deemph, pl_link_gen2_cap, pl_link_partner_gen2_supported, pl_link.upcfg_cap, rx.np_ok, rx.np_req, s_axis_tx.tdata, s_axis_tx.tkeep, s_axis_tx.tlast, s_axis_tx.tready, s_axis_tx.tuser, s_axis_tx.tvalid, tx.buf_av, tx.cfg_gnt, tx.cfg_req, tx.err_drop, user.app_rdy, user.lnk_up);
endmodule
