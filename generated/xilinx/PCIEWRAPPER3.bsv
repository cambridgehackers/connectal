
/*
   ../scripts/importbvi.py
   -I
   PcieWrap
   -P
   pcieWrap
   -n
   sys_reset
   -r
   sys_reset
   -n
   sys_clk
   -c
   sys_clk
   -n
   user_clk
   -c
   user_clk
   -n
   user_reset
   -r
   user_reset
   -n
   int_dclk_out
   -c
   int_dclk_out
   -n
   int_oobclk_out
   -c
   int_oobclk_out
   -n
   int_pipe_rxusrclk_out
   -c
   int_pipe_rxusrclk_out
   -n
   int_qplloutclk_out
   -c
   int_qplloutclk_out
   -n
   int_rxoutclk_out
   -c
   int_rxoutclk_out
   -n
   int_userclk1_out
   -n
   int_userclk2_out
   -c
   int_userclk1_out
   -c
   int_userclk2_out
   -n
   int_pclk_out_slave
   -c
   int_pclk_out_slave
   -n
   int_qplloutrefclk_out
   -c
   int_qplloutrefclk_out
   -f
   common
   -f
   int_qplllock
   -f
   int_pclk_sel
   -f
   pipe_userclk1
   -f
   pipe_userclk2
   -f
   cfg_mgmt_type1
   -f
   cfg_req_pm_transition
   -f
   pci_exp
   -f
   pipe
   -f
   user
   -o
   ../xilinx/PCIEWRAPPER3.bsv
   -p
   lanes
   ../../out/vc709/pcie3_7x_0/pcie3_7x_0_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;

(* always_ready, always_enabled *)
interface PciewrapCfg#(numeric type lanes);
    method Action      config_space_enable(Bit#(1) v);
    method Bit#(3)     current_speed();
    method Bit#(2)     dpa_substate_change();
    method Action      ds_bus_number(Bit#(8) v);
    method Action      ds_device_number(Bit#(5) v);
    method Action      ds_function_number(Bit#(3) v);
    method Action      ds_port_number(Bit#(8) v);
    method Action      dsn(Bit#(64) v);
    method Action      err_cor_in(Bit#(1) v);
    method Bit#(1)     err_cor_out();
    method Bit#(1)     err_fatal_out();
    method Bit#(1)     err_nonfatal_out();
    method Action      err_uncor_in(Bit#(1) v);
    method Action      flr_done(Bit#(2) v);
    method Bit#(2)     flr_in_process();
    method Bit#(6)     function_power_state();
    method Bit#(8)     function_status();
    method Action      hot_reset_in(Bit#(1) v);
    method Bit#(1)     hot_reset_out();
    method Action      interrupt_int(Bit#(4) v);
    method Action      interrupt_msix_address(Bit#(64) v);
    method Action      interrupt_msix_data(Bit#(32) v);
    method Bit#(2)     interrupt_msix_enable();
    method Bit#(1)     interrupt_msix_fail();
    method Action      interrupt_msix_int(Bit#(1) v);
    method Bit#(2)     interrupt_msix_mask();
    method Bit#(1)     interrupt_msix_sent();
    method Bit#(6)     interrupt_msix_vf_enable();
    method Bit#(6)     interrupt_msix_vf_mask();
    method Action      interrupt_pending(Bit#(2) v);
    method Bit#(1)     interrupt_sent();
    method Bit#(2)     link_power_state();
    method Action      link_training_enable(Bit#(1) v);
    method Bit#(1)     ltr_enable();
    method Bit#(6)     ltssm_state();
    method Bit#(3)     max_payload();
    method Bit#(3)     max_read_req();
    method Bit#(4)     negotiated_width();
    method Bit#(2)     obff_enable();
    method Action      per_function_number(Bit#(3) v);
    method Action      per_function_output_request(Bit#(1) v);
    method Bit#(1)     per_function_update_done();
    method Bit#(1)     phy_link_down();
    method Bit#(2)     phy_link_status();
    method Bit#(1)     pl_status_change();
    method Action      power_state_change_ack(Bit#(1) v);
    method Bit#(1)     power_state_change_interrupt();
    method Bit#(2)     rcb_status();
    method Action      subsys_vend_id(Bit#(16) v);
    method Bit#(2)     tph_requester_enable();
    method Bit#(6)     tph_st_mode();
    method Action      vf_flr_done(Bit#(6) v);
    method Bit#(6)     vf_flr_in_process();
    method Bit#(18)     vf_power_state();
    method Bit#(12)     vf_status();
    method Bit#(6)     vf_tph_requester_enable();
    method Bit#(18)     vf_tph_st_mode();
endinterface
(* always_ready, always_enabled *)
interface PciewrapCfg_req_pm_transition#(numeric type lanes);
    method Action      l23_ready(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapCommon#(numeric type lanes);
    method Action      commands_in(Bit#(26) v);
    method Bit#(17)     commands_out();
endinterface
(* always_ready, always_enabled *)
interface PciewrapInt_pclk_sel#(numeric type lanes);
    method Action      slave(Bit#(8) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapInt_qplllock#(numeric type lanes);
    method Bit#(2)     out();
endinterface
(* always_ready, always_enabled *)
interface PciewrapM_axis_cq#(numeric type lanes);
    method Bit#(256)     tdata();
    method Bit#(8)     tkeep();
    method Bit#(1)     tlast();
    method Action      tready(Bit#(1) v);
    method Bit#(85)     tuser();
    method Bit#(1)     tvalid();
endinterface
(* always_ready, always_enabled *)
interface PciewrapM_axis_rc#(numeric type lanes);
    method Bit#(256)     tdata();
    method Bit#(8)     tkeep();
    method Bit#(1)     tlast();
    method Action      tready(Bit#(1) v);
    method Bit#(75)     tuser();
    method Bit#(1)     tvalid();
endinterface
(* always_ready, always_enabled *)
interface PciewrapPci_exp#(numeric type lanes);
    method Action      rxn(Bit#(8) v);
    method Action      rxp(Bit#(8) v);
    method Bit#(8)     txn();
    method Bit#(8)     txp();
endinterface
(* always_ready, always_enabled *)
interface PciewrapPcie#(numeric type lanes);
    method Action      cq_np_req(Bit#(1) v);
    method Bit#(6)     cq_np_req_count();
    method Bit#(4)     rq_seq_num();
    method Bit#(1)     rq_seq_num_vld();
    method Bit#(6)     rq_tag();
    method Bit#(1)     rq_tag_vld();
endinterface
(* always_ready, always_enabled *)
interface PciewrapPipe#(numeric type lanes);
    method Action      rx_0_sigs(Bit#(84) v);
    method Action      rx_1_sigs(Bit#(84) v);
    method Action      rx_2_sigs(Bit#(84) v);
    method Action      rx_3_sigs(Bit#(84) v);
    method Action      rx_4_sigs(Bit#(84) v);
    method Action      rx_5_sigs(Bit#(84) v);
    method Action      rx_6_sigs(Bit#(84) v);
    method Action      rx_7_sigs(Bit#(84) v);
    method Bit#(70)     tx_0_sigs();
    method Bit#(70)     tx_1_sigs();
    method Bit#(70)     tx_2_sigs();
    method Bit#(70)     tx_3_sigs();
    method Bit#(70)     tx_4_sigs();
    method Bit#(70)     tx_5_sigs();
    method Bit#(70)     tx_6_sigs();
    method Bit#(70)     tx_7_sigs();
endinterface
(* always_ready, always_enabled *)
interface PciewrapS_axis_cc#(numeric type lanes);
    method Action      tdata(Bit#(256) v);
    method Action      tkeep(Bit#(8) v);
    method Action      tlast(Bit#(1) v);
    method Bit#(4)     tready();
    method Action      tuser(Bit#(33) v);
    method Action      tvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapS_axis_rq#(numeric type lanes);
    method Action      tdata(Bit#(256) v);
    method Action      tkeep(Bit#(8) v);
    method Action      tlast(Bit#(1) v);
    method Bit#(4)     tready();
    method Action      tuser(Bit#(60) v);
    method Action      tvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciewrapUser#(numeric type lanes);
    method Bit#(1)     app_rdy();
    method Bit#(1)     lnk_up();
endinterface
(* always_ready, always_enabled *)
interface PcieWrap#(numeric type lanes);
    interface PciewrapCfg#(lanes)     cfg;
    interface PciewrapCfg_req_pm_transition#(lanes)     cfg_req_pm_transition;
    interface PciewrapCommon#(lanes)     common;
    interface Clock     int_dclk_out;
    interface Clock     int_oobclk_out;
    interface Clock     int_pclk_out_slave;
    interface PciewrapInt_pclk_sel#(lanes)     int_pclk_sel;
    interface Clock     int_pipe_rxusrclk_out;
    interface PciewrapInt_qplllock#(lanes)     int_qplllock;
    interface Clock     int_qplloutclk_out;
    interface Clock     int_qplloutrefclk_out;
    interface Clock     int_rxoutclk_out;
    interface Clock     int_userclk1_out;
    interface Clock     int_userclk2_out;
    interface PciewrapM_axis_cq#(lanes)     m_axis_cq;
    interface PciewrapM_axis_rc#(lanes)     m_axis_rc;
    interface PciewrapPci_exp#(lanes)     pci_exp;
    interface PciewrapPcie#(lanes)     pcie;
    interface PciewrapPipe#(lanes)     pipe;
    interface PciewrapS_axis_cc#(lanes)     s_axis_cc;
    interface PciewrapS_axis_rq#(lanes)     s_axis_rq;
    interface PciewrapUser#(lanes)     user;
    interface Clock     user_clk;
    method Reset     user_reset();
endinterface
import "BVI" pcie3_7x_0 =
module mkPcieWrap#(Clock sys_clk, Reset sys_reset)(PcieWrap#(lanes));
    let lanes = valueOf(lanes);
    output_clock user_clk(user_clk);
    output_reset user_reset(user_reset);
    default_clock sys_clk(sys_clk) = sys_clk;
     /* from clock*/
    default_reset sys_reset(sys_reset) = sys_reset;
    interface PciewrapCfg     cfg;
        method config_space_enable(cfg_config_space_enable) enable((*inhigh*) EN_cfg_config_space_enable) clocked_by (user_clk) reset_by (user_reset);
        method cfg_current_speed current_speed() clocked_by (user_clk) reset_by (user_reset);
        method cfg_dpa_substate_change dpa_substate_change() clocked_by (user_clk) reset_by (user_reset);
        method ds_bus_number(cfg_ds_bus_number) enable((*inhigh*) EN_cfg_ds_bus_number) clocked_by (user_clk) reset_by (user_reset);
        method ds_device_number(cfg_ds_device_number) enable((*inhigh*) EN_cfg_ds_device_number) clocked_by (user_clk) reset_by (user_reset);
        method ds_function_number(cfg_ds_function_number) enable((*inhigh*) EN_cfg_ds_function_number) clocked_by (user_clk) reset_by (user_reset);
        method ds_port_number(cfg_ds_port_number) enable((*inhigh*) EN_cfg_ds_port_number) clocked_by (user_clk) reset_by (user_reset);
        method dsn(cfg_dsn) enable((*inhigh*) EN_cfg_dsn) clocked_by (user_clk) reset_by (user_reset);
        method err_cor_in(cfg_err_cor_in) enable((*inhigh*) EN_cfg_err_cor_in) clocked_by (user_clk) reset_by (user_reset);
        method cfg_err_cor_out err_cor_out() clocked_by (user_clk) reset_by (user_reset);
        method cfg_err_fatal_out err_fatal_out() clocked_by (user_clk) reset_by (user_reset);
        method cfg_err_nonfatal_out err_nonfatal_out() clocked_by (user_clk) reset_by (user_reset);
        method err_uncor_in(cfg_err_uncor_in) enable((*inhigh*) EN_cfg_err_uncor_in) clocked_by (user_clk) reset_by (user_reset);
        method flr_done(cfg_flr_done) enable((*inhigh*) EN_cfg_flr_done) clocked_by (user_clk) reset_by (user_reset);
        method cfg_flr_in_process flr_in_process() clocked_by (user_clk) reset_by (user_reset);
        method cfg_function_power_state function_power_state() clocked_by (user_clk) reset_by (user_reset);
        method cfg_function_status function_status() clocked_by (user_clk) reset_by (user_reset);
        method hot_reset_in(cfg_hot_reset_in) enable((*inhigh*) EN_cfg_hot_reset_in) clocked_by (user_clk) reset_by (user_reset);
        method cfg_hot_reset_out hot_reset_out() clocked_by (user_clk) reset_by (user_reset);
        method interrupt_int(cfg_interrupt_int) enable((*inhigh*) EN_cfg_interrupt_int) clocked_by (user_clk) reset_by (user_reset);
        method interrupt_msix_address(cfg_interrupt_msix_address) enable((*inhigh*) EN_cfg_interrupt_msix_address) clocked_by (user_clk) reset_by (user_reset);
        method interrupt_msix_data(cfg_interrupt_msix_data) enable((*inhigh*) EN_cfg_interrupt_msix_data) clocked_by (user_clk) reset_by (user_reset);
        method cfg_interrupt_msix_enable interrupt_msix_enable() clocked_by (user_clk) reset_by (user_reset);
        method cfg_interrupt_msix_fail interrupt_msix_fail() clocked_by (user_clk) reset_by (user_reset);
        method interrupt_msix_int(cfg_interrupt_msix_int) enable((*inhigh*) EN_cfg_interrupt_msix_int) clocked_by (user_clk) reset_by (user_reset);
        method cfg_interrupt_msix_mask interrupt_msix_mask() clocked_by (user_clk) reset_by (user_reset);
        method cfg_interrupt_msix_sent interrupt_msix_sent() clocked_by (user_clk) reset_by (user_reset);
        method cfg_interrupt_msix_vf_enable interrupt_msix_vf_enable() clocked_by (user_clk) reset_by (user_reset);
        method cfg_interrupt_msix_vf_mask interrupt_msix_vf_mask() clocked_by (user_clk) reset_by (user_reset);
        method interrupt_pending(cfg_interrupt_pending) enable((*inhigh*) EN_cfg_interrupt_pending) clocked_by (user_clk) reset_by (user_reset);
        method cfg_interrupt_sent interrupt_sent() clocked_by (user_clk) reset_by (user_reset);
        method cfg_link_power_state link_power_state() clocked_by (user_clk) reset_by (user_reset);
        method link_training_enable(cfg_link_training_enable) enable((*inhigh*) EN_cfg_link_training_enable) clocked_by (user_clk) reset_by (user_reset);
        method cfg_ltr_enable ltr_enable() clocked_by (user_clk) reset_by (user_reset);
        method cfg_ltssm_state ltssm_state() clocked_by (user_clk) reset_by (user_reset);
        method cfg_max_payload max_payload() clocked_by (user_clk) reset_by (user_reset);
        method cfg_max_read_req max_read_req() clocked_by (user_clk) reset_by (user_reset);
        method cfg_negotiated_width negotiated_width() clocked_by (user_clk) reset_by (user_reset);
        method cfg_obff_enable obff_enable() clocked_by (user_clk) reset_by (user_reset);
        method per_function_number(cfg_per_function_number) enable((*inhigh*) EN_cfg_per_function_number) clocked_by (user_clk) reset_by (user_reset);
        method per_function_output_request(cfg_per_function_output_request) enable((*inhigh*) EN_cfg_per_function_output_request) clocked_by (user_clk) reset_by (user_reset);
        method cfg_per_function_update_done per_function_update_done() clocked_by (user_clk) reset_by (user_reset);
        method cfg_phy_link_down phy_link_down() clocked_by (user_clk) reset_by (user_reset);
        method cfg_phy_link_status phy_link_status() clocked_by (user_clk) reset_by (user_reset);
        method cfg_pl_status_change pl_status_change() clocked_by (user_clk) reset_by (user_reset);
        method power_state_change_ack(cfg_power_state_change_ack) enable((*inhigh*) EN_cfg_power_state_change_ack) clocked_by (user_clk) reset_by (user_reset);
        method cfg_power_state_change_interrupt power_state_change_interrupt() clocked_by (user_clk) reset_by (user_reset);
        method cfg_rcb_status rcb_status() clocked_by (user_clk) reset_by (user_reset);
        method subsys_vend_id(cfg_subsys_vend_id) enable((*inhigh*) EN_cfg_subsys_vend_id) clocked_by (user_clk) reset_by (user_reset);
        method cfg_tph_requester_enable tph_requester_enable() clocked_by (user_clk) reset_by (user_reset);
        method cfg_tph_st_mode tph_st_mode() clocked_by (user_clk) reset_by (user_reset);
        method vf_flr_done(cfg_vf_flr_done) enable((*inhigh*) EN_cfg_vf_flr_done) clocked_by (user_clk) reset_by (user_reset);
        method cfg_vf_flr_in_process vf_flr_in_process() clocked_by (user_clk) reset_by (user_reset);
        method cfg_vf_power_state vf_power_state() clocked_by (user_clk) reset_by (user_reset);
        method cfg_vf_status vf_status() clocked_by (user_clk) reset_by (user_reset);
        method cfg_vf_tph_requester_enable vf_tph_requester_enable() clocked_by (user_clk) reset_by (user_reset);
        method cfg_vf_tph_st_mode vf_tph_st_mode() clocked_by (user_clk) reset_by (user_reset);
    endinterface
    interface PciewrapCfg_req_pm_transition     cfg_req_pm_transition;
        method l23_ready(cfg_req_pm_transition_l23_ready) enable((*inhigh*) EN_cfg_req_pm_transition_l23_ready) clocked_by (user_clk) reset_by (user_reset);
    endinterface
    interface PciewrapCommon     common;
        method commands_in(common_commands_in) enable((*inhigh*) EN_common_commands_in) clocked_by (user_clk) reset_by (user_reset);
        method common_commands_out commands_out();
    endinterface
    output_clock int_dclk_out(int_dclk_out);
    output_clock int_oobclk_out(int_oobclk_out);
    output_clock int_pclk_out_slave(int_pclk_out_slave);
    interface PciewrapInt_pclk_sel     int_pclk_sel;
        method slave(int_pclk_sel_slave) enable((*inhigh*) EN_int_pclk_sel_slave) clocked_by (user_clk) reset_by (user_reset);
    endinterface
    output_clock int_pipe_rxusrclk_out(int_pipe_rxusrclk_out);
    interface PciewrapInt_qplllock     int_qplllock;
        method int_qplllock_out out();
    endinterface
    output_clock int_qplloutclk_out(int_qplloutclk_out);
    output_clock int_qplloutrefclk_out(int_qplloutrefclk_out);
    output_clock int_rxoutclk_out(int_rxoutclk_out);
    output_clock int_userclk1_out(int_userclk1_out);
    output_clock int_userclk2_out(int_userclk2_out);
    interface PciewrapM_axis_cq     m_axis_cq;
        method m_axis_cq_tdata tdata() clocked_by (user_clk) reset_by (user_reset);
        method m_axis_cq_tkeep tkeep() clocked_by (user_clk) reset_by (user_reset);
        method m_axis_cq_tlast tlast() clocked_by (user_clk) reset_by (user_reset);
        method tready(m_axis_cq_tready) enable((*inhigh*) EN_m_axis_cq_tready) clocked_by (user_clk) reset_by (user_reset);
        method m_axis_cq_tuser tuser() clocked_by (user_clk) reset_by (user_reset);
        method m_axis_cq_tvalid tvalid() clocked_by (user_clk) reset_by (user_reset);
    endinterface
    interface PciewrapM_axis_rc     m_axis_rc;
        method m_axis_rc_tdata tdata() clocked_by (user_clk) reset_by (user_reset);
        method m_axis_rc_tkeep tkeep() clocked_by (user_clk) reset_by (user_reset);
        method m_axis_rc_tlast tlast() clocked_by (user_clk) reset_by (user_reset);
        method tready(m_axis_rc_tready) enable((*inhigh*) EN_m_axis_rc_tready) clocked_by (user_clk) reset_by (user_reset);
        method m_axis_rc_tuser tuser() clocked_by (user_clk) reset_by (user_reset);
        method m_axis_rc_tvalid tvalid() clocked_by (user_clk) reset_by (user_reset);
    endinterface
    interface PciewrapPci_exp     pci_exp;
        method rxn(pci_exp_rxn) enable((*inhigh*) EN_pci_exp_rxn)  clocked_by (sys_clk) reset_by (sys_reset);
        method rxp(pci_exp_rxp) enable((*inhigh*) EN_pci_exp_rxp)  clocked_by (sys_clk) reset_by (sys_reset);
        method pci_exp_txn txn() clocked_by (sys_clk) reset_by (sys_reset);
        method pci_exp_txp txp() clocked_by (sys_clk) reset_by (sys_reset);
    endinterface
    interface PciewrapPcie     pcie;
        method cq_np_req(pcie_cq_np_req) enable((*inhigh*) EN_pcie_cq_np_req) clocked_by (user_clk) reset_by (user_reset);
        method pcie_cq_np_req_count cq_np_req_count() clocked_by (user_clk) reset_by (user_reset);
        method pcie_rq_seq_num rq_seq_num() clocked_by (user_clk) reset_by (user_reset);
        method pcie_rq_seq_num_vld rq_seq_num_vld() clocked_by (user_clk) reset_by (user_reset);
        method pcie_rq_tag rq_tag() clocked_by (user_clk) reset_by (user_reset);
        method pcie_rq_tag_vld rq_tag_vld() clocked_by (user_clk) reset_by (user_reset);
    endinterface
    interface PciewrapPipe     pipe;
        method rx_0_sigs(pipe_rx_0_sigs) enable((*inhigh*) EN_pipe_rx_0_sigs)  clocked_by (sys_clk) reset_by (sys_reset);
        method rx_1_sigs(pipe_rx_1_sigs) enable((*inhigh*) EN_pipe_rx_1_sigs)  clocked_by (sys_clk) reset_by (sys_reset);
        method rx_2_sigs(pipe_rx_2_sigs) enable((*inhigh*) EN_pipe_rx_2_sigs)  clocked_by (sys_clk) reset_by (sys_reset);
        method rx_3_sigs(pipe_rx_3_sigs) enable((*inhigh*) EN_pipe_rx_3_sigs)  clocked_by (sys_clk) reset_by (sys_reset);
        method rx_4_sigs(pipe_rx_4_sigs) enable((*inhigh*) EN_pipe_rx_4_sigs)  clocked_by (sys_clk) reset_by (sys_reset);
        method rx_5_sigs(pipe_rx_5_sigs) enable((*inhigh*) EN_pipe_rx_5_sigs)  clocked_by (sys_clk) reset_by (sys_reset);
        method rx_6_sigs(pipe_rx_6_sigs) enable((*inhigh*) EN_pipe_rx_6_sigs)  clocked_by (sys_clk) reset_by (sys_reset);
        method rx_7_sigs(pipe_rx_7_sigs) enable((*inhigh*) EN_pipe_rx_7_sigs)  clocked_by (sys_clk) reset_by (sys_reset);
        method pipe_tx_0_sigs tx_0_sigs();
        method pipe_tx_1_sigs tx_1_sigs();
        method pipe_tx_2_sigs tx_2_sigs();
        method pipe_tx_3_sigs tx_3_sigs();
        method pipe_tx_4_sigs tx_4_sigs();
        method pipe_tx_5_sigs tx_5_sigs();
        method pipe_tx_6_sigs tx_6_sigs();
        method pipe_tx_7_sigs tx_7_sigs();
    endinterface
    interface PciewrapS_axis_cc     s_axis_cc;
        method tdata(s_axis_cc_tdata) enable((*inhigh*) EN_s_axis_cc_tdata) clocked_by (user_clk) reset_by (user_reset);
        method tkeep(s_axis_cc_tkeep) enable((*inhigh*) EN_s_axis_cc_tkeep) clocked_by (user_clk) reset_by (user_reset);
        method tlast(s_axis_cc_tlast) enable((*inhigh*) EN_s_axis_cc_tlast) clocked_by (user_clk) reset_by (user_reset);
        method s_axis_cc_tready tready() clocked_by (user_clk) reset_by (user_reset);
        method tuser(s_axis_cc_tuser) enable((*inhigh*) EN_s_axis_cc_tuser) clocked_by (user_clk) reset_by (user_reset);
        method tvalid(s_axis_cc_tvalid) enable((*inhigh*) EN_s_axis_cc_tvalid) clocked_by (user_clk) reset_by (user_reset);
    endinterface
    interface PciewrapS_axis_rq     s_axis_rq;
        method tdata(s_axis_rq_tdata) enable((*inhigh*) EN_s_axis_rq_tdata) clocked_by (user_clk) reset_by (user_reset);
        method tkeep(s_axis_rq_tkeep) enable((*inhigh*) EN_s_axis_rq_tkeep) clocked_by (user_clk) reset_by (user_reset);
        method tlast(s_axis_rq_tlast) enable((*inhigh*) EN_s_axis_rq_tlast) clocked_by (user_clk) reset_by (user_reset);
        method s_axis_rq_tready tready() clocked_by (user_clk) reset_by (user_reset);
        method tuser(s_axis_rq_tuser) enable((*inhigh*) EN_s_axis_rq_tuser) clocked_by (user_clk) reset_by (user_reset);
        method tvalid(s_axis_rq_tvalid) enable((*inhigh*) EN_s_axis_rq_tvalid) clocked_by (user_clk) reset_by (user_reset);
    endinterface
    interface PciewrapUser     user;
        method user_app_rdy app_rdy() clocked_by (user_clk) reset_by (user_reset);
        method user_lnk_up lnk_up() clocked_by (user_clk) reset_by (user_reset);
    endinterface
    
    
    schedule (cfg.config_space_enable, cfg.current_speed, cfg.dpa_substate_change, cfg.ds_bus_number, cfg.ds_device_number, cfg.ds_function_number, cfg.ds_port_number, cfg.dsn, cfg.err_cor_in, cfg.err_cor_out, cfg.err_fatal_out, cfg.err_nonfatal_out, cfg.err_uncor_in, cfg.flr_done, cfg.flr_in_process, cfg.function_power_state, cfg.function_status, cfg.hot_reset_in, cfg.hot_reset_out, cfg.interrupt_int, cfg.interrupt_msix_address, cfg.interrupt_msix_data, cfg.interrupt_msix_enable, cfg.interrupt_msix_fail, cfg.interrupt_msix_int, cfg.interrupt_msix_mask, cfg.interrupt_msix_sent, cfg.interrupt_msix_vf_enable, cfg.interrupt_msix_vf_mask, cfg.interrupt_pending, cfg.interrupt_sent, cfg.link_power_state, cfg.link_training_enable, cfg.ltr_enable, cfg.ltssm_state, cfg.max_payload, cfg.max_read_req, cfg.negotiated_width, cfg.obff_enable, cfg.per_function_number, cfg.per_function_output_request, cfg.per_function_update_done, cfg.phy_link_down, cfg.phy_link_status, cfg.pl_status_change, cfg.power_state_change_ack, cfg.power_state_change_interrupt, cfg.rcb_status, cfg.subsys_vend_id, cfg.tph_requester_enable, cfg.tph_st_mode, cfg.vf_flr_done, cfg.vf_flr_in_process, cfg.vf_power_state, cfg.vf_status, cfg.vf_tph_requester_enable, cfg.vf_tph_st_mode, cfg_req_pm_transition.l23_ready, common.commands_in, common.commands_out, int_pclk_sel.slave, int_qplllock.out, m_axis_cq.tdata, m_axis_cq.tkeep, m_axis_cq.tlast, m_axis_cq.tready, m_axis_cq.tuser, m_axis_cq.tvalid, m_axis_rc.tdata, m_axis_rc.tkeep, m_axis_rc.tlast, m_axis_rc.tready, m_axis_rc.tuser, m_axis_rc.tvalid, pci_exp.rxn, pci_exp.rxp, pci_exp.txn, pci_exp.txp, pcie.cq_np_req, pcie.cq_np_req_count, pcie.rq_seq_num, pcie.rq_seq_num_vld, pcie.rq_tag, pcie.rq_tag_vld, pipe.rx_0_sigs, pipe.rx_1_sigs, pipe.rx_2_sigs, pipe.rx_3_sigs, pipe.rx_4_sigs, pipe.rx_5_sigs, pipe.rx_6_sigs, pipe.rx_7_sigs, pipe.tx_0_sigs, pipe.tx_1_sigs, pipe.tx_2_sigs, pipe.tx_3_sigs, pipe.tx_4_sigs, pipe.tx_5_sigs, pipe.tx_6_sigs, pipe.tx_7_sigs, s_axis_cc.tdata, s_axis_cc.tkeep, s_axis_cc.tlast, s_axis_cc.tready, s_axis_cc.tuser, s_axis_cc.tvalid, s_axis_rq.tdata, s_axis_rq.tkeep, s_axis_rq.tlast, s_axis_rq.tready, s_axis_rq.tuser, s_axis_rq.tvalid, user.app_rdy, user.lnk_up) CF (cfg.config_space_enable, cfg.current_speed, cfg.dpa_substate_change, cfg.ds_bus_number, cfg.ds_device_number, cfg.ds_function_number, cfg.ds_port_number, cfg.dsn, cfg.err_cor_in, cfg.err_cor_out, cfg.err_fatal_out, cfg.err_nonfatal_out, cfg.err_uncor_in, cfg.flr_done, cfg.flr_in_process, cfg.function_power_state, cfg.function_status, cfg.hot_reset_in, cfg.hot_reset_out, cfg.interrupt_int, cfg.interrupt_msix_address, cfg.interrupt_msix_data, cfg.interrupt_msix_enable, cfg.interrupt_msix_fail, cfg.interrupt_msix_int, cfg.interrupt_msix_mask, cfg.interrupt_msix_sent, cfg.interrupt_msix_vf_enable, cfg.interrupt_msix_vf_mask, cfg.interrupt_pending, cfg.interrupt_sent, cfg.link_power_state, cfg.link_training_enable, cfg.ltr_enable, cfg.ltssm_state, cfg.max_payload, cfg.max_read_req, cfg.negotiated_width, cfg.obff_enable, cfg.per_function_number, cfg.per_function_output_request, cfg.per_function_update_done, cfg.phy_link_down, cfg.phy_link_status, cfg.pl_status_change, cfg.power_state_change_ack, cfg.power_state_change_interrupt, cfg.rcb_status, cfg.subsys_vend_id, cfg.tph_requester_enable, cfg.tph_st_mode, cfg.vf_flr_done, cfg.vf_flr_in_process, cfg.vf_power_state, cfg.vf_status, cfg.vf_tph_requester_enable, cfg.vf_tph_st_mode, cfg_req_pm_transition.l23_ready, common.commands_in, common.commands_out, int_pclk_sel.slave, int_qplllock.out, m_axis_cq.tdata, m_axis_cq.tkeep, m_axis_cq.tlast, m_axis_cq.tready, m_axis_cq.tuser, m_axis_cq.tvalid, m_axis_rc.tdata, m_axis_rc.tkeep, m_axis_rc.tlast, m_axis_rc.tready, m_axis_rc.tuser, m_axis_rc.tvalid, pci_exp.rxn, pci_exp.rxp, pci_exp.txn, pci_exp.txp, pcie.cq_np_req, pcie.cq_np_req_count, pcie.rq_seq_num, pcie.rq_seq_num_vld, pcie.rq_tag, pcie.rq_tag_vld, pipe.rx_0_sigs, pipe.rx_1_sigs, pipe.rx_2_sigs, pipe.rx_3_sigs, pipe.rx_4_sigs, pipe.rx_5_sigs, pipe.rx_6_sigs, pipe.rx_7_sigs, pipe.tx_0_sigs, pipe.tx_1_sigs, pipe.tx_2_sigs, pipe.tx_3_sigs, pipe.tx_4_sigs, pipe.tx_5_sigs, pipe.tx_6_sigs, pipe.tx_7_sigs, s_axis_cc.tdata, s_axis_cc.tkeep, s_axis_cc.tlast, s_axis_cc.tready, s_axis_cc.tuser, s_axis_cc.tvalid, s_axis_rq.tdata, s_axis_rq.tkeep, s_axis_rq.tlast, s_axis_rq.tready, s_axis_rq.tuser, s_axis_rq.tvalid, user.app_rdy, user.lnk_up);
endmodule
