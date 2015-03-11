
/*
   ../scripts/importbvi.py
   -I
   Pcie3Wrap
   -P
   pcie3Wrap
   -f
   pipe_gen3
   -f
   int_userclk1
   -f
   int_userclk2
   -f
   pipe_userclk1
   -f
   pipe_userclk2
   -f
   cfg_mgmt_type1
   -f
   cfg_req_pm_transition_l23
   -o
   ../xilinx/PCIEWRAPPER3.bsv
   ../../out/netfpgasume/pcie3_7x_0/pcie3_7x_0_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface Pcie3wrapCfg;
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
    method Bit#(8)     ext_function_number();
    method Action      ext_read_data(Bit#(32) v);
    method Action      ext_read_data_valid(Bit#(1) v);
    method Bit#(1)     ext_read_received();
    method Bit#(10)     ext_register_number();
    method Bit#(4)     ext_write_byte_enable();
    method Bit#(32)     ext_write_data();
    method Bit#(1)     ext_write_received();
    method Bit#(12)     fc_cpld();
    method Bit#(8)     fc_cplh();
    method Bit#(12)     fc_npd();
    method Bit#(8)     fc_nph();
    method Bit#(12)     fc_pd();
    method Bit#(8)     fc_ph();
    method Action      fc_sel(Bit#(3) v);
    method Action      flr_done(Bit#(2) v);
    method Bit#(2)     flr_in_process();
    method Bit#(6)     function_power_state();
    method Bit#(8)     function_status();
    method Action      hot_reset_in(Bit#(1) v);
    method Bit#(1)     hot_reset_out();
    method Action      interrupt_int(Bit#(4) v);
    method Action      interrupt_msi_attr(Bit#(3) v);
    method Bit#(32)     interrupt_msi_data();
    method Bit#(2)     interrupt_msi_enable();
    method Bit#(1)     interrupt_msi_fail();
    method Action      interrupt_msi_function_number(Bit#(3) v);
    method Action      interrupt_msi_int(Bit#(32) v);
    method Bit#(1)     interrupt_msi_mask_update();
    method Bit#(6)     interrupt_msi_mmenable();
    method Action      interrupt_msi_pending_status(Bit#(64) v);
    method Action      interrupt_msi_select(Bit#(4) v);
    method Bit#(1)     interrupt_msi_sent();
    method Action      interrupt_msi_tph_present(Bit#(1) v);
    method Action      interrupt_msi_tph_st_tag(Bit#(9) v);
    method Action      interrupt_msi_tph_type(Bit#(2) v);
    method Bit#(6)     interrupt_msi_vf_enable();
    method Action      interrupt_pending(Bit#(2) v);
    method Bit#(1)     interrupt_sent();
    method Bit#(2)     link_power_state();
    method Action      link_training_enable(Bit#(1) v);
    method Bit#(1)     ltr_enable();
    method Bit#(6)     ltssm_state();
    method Bit#(3)     max_payload();
    method Bit#(3)     max_read_req();
    method Action      mgmt_addr(Bit#(19) v);
    method Action      mgmt_byte_enable(Bit#(4) v);
    method Action      mgmt_read(Bit#(1) v);
    method Bit#(32)     mgmt_read_data();
    method Bit#(1)     mgmt_read_write_done();
    method Action      mgmt_write(Bit#(1) v);
    method Action      mgmt_write_data(Bit#(32) v);
    method Bit#(1)     msg_received();
    method Bit#(8)     msg_received_data();
    method Bit#(5)     msg_received_type();
    method Action      msg_transmit(Bit#(1) v);
    method Action      msg_transmit_data(Bit#(32) v);
    method Bit#(1)     msg_transmit_done();
    method Action      msg_transmit_type(Bit#(3) v);
    method Bit#(4)     negotiated_width();
    method Bit#(2)     obff_enable();
    method Action      per_func_status_control(Bit#(3) v);
    method Bit#(16)     per_func_status_data();
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
interface Pcie3wrapCfg_mgmt_type1;
    method Action      cfg_reg_access(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Pcie3wrapCfg_req_pm_transition_l23;
    method Action      ready(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Pcie3wrapInt;
    method Bit#(1)     dclk_out();
    method Bit#(1)     oobclk_out();
    method Bit#(1)     pclk_out_slave();
    method Action      pclk_sel_slave(Bit#(8) v);
    method Bit#(1)     pipe_rxusrclk_out();
    method Bit#(2)     qplllock_out();
    method Bit#(2)     qplloutclk_out();
    method Bit#(2)     qplloutrefclk_out();
    method Bit#(8)     rxoutclk_out();
endinterface
(* always_ready, always_enabled *)
interface Pcie3wrapInt_userclk1;
    method Bit#(1)     out();
endinterface
(* always_ready, always_enabled *)
interface Pcie3wrapInt_userclk2;
    method Bit#(1)     out();
endinterface
(* always_ready, always_enabled *)
interface Pcie3wrapM_axis_cq;
    method Bit#(256)     tdata();
    method Bit#(8)     tkeep();
    method Bit#(1)     tlast();
    method Action      tready(Bit#(22) v);
    method Bit#(85)     tuser();
    method Bit#(1)     tvalid();
endinterface
(* always_ready, always_enabled *)
interface Pcie3wrapM_axis_rc;
    method Bit#(256)     tdata();
    method Bit#(8)     tkeep();
    method Bit#(1)     tlast();
    method Action      tready(Bit#(22) v);
    method Bit#(75)     tuser();
    method Bit#(1)     tvalid();
endinterface
(* always_ready, always_enabled *)
interface Pcie3wrapPci;
    method Action      exp_rxn(Bit#(8) v);
    method Action      exp_rxp(Bit#(8) v);
    method Bit#(8)     exp_txn();
    method Bit#(8)     exp_txp();
endinterface
(* always_ready, always_enabled *)
interface Pcie3wrapPcie;
    method Action      cq_np_req(Bit#(1) v);
    method Bit#(6)     cq_np_req_count();
    method Bit#(4)     rq_seq_num();
    method Bit#(1)     rq_seq_num_vld();
    method Bit#(6)     rq_tag();
    method Bit#(1)     rq_tag_vld();
    method Bit#(2)     tfc_npd_av();
    method Bit#(2)     tfc_nph_av();
endinterface
(* always_ready, always_enabled *)
interface Pcie3wrapS_axis_cc;
    method Action      tdata(Bit#(256) v);
    method Action      tkeep(Bit#(8) v);
    method Action      tlast(Bit#(1) v);
    method Bit#(4)     tready();
    method Action      tuser(Bit#(33) v);
    method Action      tvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Pcie3wrapS_axis_rq;
    method Action      tdata(Bit#(256) v);
    method Action      tkeep(Bit#(8) v);
    method Action      tlast(Bit#(1) v);
    method Bit#(4)     tready();
    method Action      tuser(Bit#(60) v);
    method Action      tvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Pcie3wrapSys;
    method Action      clk(Bit#(1) v);
    method Action      reset(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Pcie3wrapUser;
    method Bit#(1)     app_rdy();
    method Bit#(1)     clk();
    method Bit#(1)     lnk_up();
    method Bit#(1)     reset();
endinterface
(* always_ready, always_enabled *)
interface Pcie3Wrap;
    interface Pcie3wrapCfg     cfg;
    interface Pcie3wrapCfg_mgmt_type1     cfg_mgmt_type1;
    interface Pcie3wrapCfg_req_pm_transition_l23     cfg_req_pm_transition_l23;
    interface Pcie3wrapInt     int;
    interface Pcie3wrapInt_userclk1     int_userclk1;
    interface Pcie3wrapInt_userclk2     int_userclk2;
    interface Pcie3wrapM_axis_cq     m_axis_cq;
    interface Pcie3wrapM_axis_rc     m_axis_rc;
    interface Pcie3wrapPci     pci;
    interface Pcie3wrapPcie     pcie;
    interface Pcie3wrapS_axis_cc     s_axis_cc;
    interface Pcie3wrapS_axis_rq     s_axis_rq;
    interface Pcie3wrapSys     sys;
    interface Pcie3wrapUser     user;
endinterface
import "BVI" pcie3_7x_0(pci_exp_txn, =
module mkPcie3Wrap(Pcie3Wrap);
    default_clock clk();
    default_reset rst();
    interface Pcie3wrapCfg     cfg;
        method config_space_enable(cfg_config_space_enable) enable((*inhigh*) EN_cfg_config_space_enable);
        method cfg_current_speed current_speed();
        method cfg_dpa_substate_change dpa_substate_change();
        method ds_bus_number(cfg_ds_bus_number) enable((*inhigh*) EN_cfg_ds_bus_number);
        method ds_device_number(cfg_ds_device_number) enable((*inhigh*) EN_cfg_ds_device_number);
        method ds_function_number(cfg_ds_function_number) enable((*inhigh*) EN_cfg_ds_function_number);
        method ds_port_number(cfg_ds_port_number) enable((*inhigh*) EN_cfg_ds_port_number);
        method dsn(cfg_dsn) enable((*inhigh*) EN_cfg_dsn);
        method err_cor_in(cfg_err_cor_in) enable((*inhigh*) EN_cfg_err_cor_in);
        method cfg_err_cor_out err_cor_out();
        method cfg_err_fatal_out err_fatal_out();
        method cfg_err_nonfatal_out err_nonfatal_out();
        method err_uncor_in(cfg_err_uncor_in) enable((*inhigh*) EN_cfg_err_uncor_in);
        method cfg_ext_function_number ext_function_number();
        method ext_read_data(cfg_ext_read_data) enable((*inhigh*) EN_cfg_ext_read_data);
        method ext_read_data_valid(cfg_ext_read_data_valid) enable((*inhigh*) EN_cfg_ext_read_data_valid);
        method cfg_ext_read_received ext_read_received();
        method cfg_ext_register_number ext_register_number();
        method cfg_ext_write_byte_enable ext_write_byte_enable();
        method cfg_ext_write_data ext_write_data();
        method cfg_ext_write_received ext_write_received();
        method cfg_fc_cpld fc_cpld();
        method cfg_fc_cplh fc_cplh();
        method cfg_fc_npd fc_npd();
        method cfg_fc_nph fc_nph();
        method cfg_fc_pd fc_pd();
        method cfg_fc_ph fc_ph();
        method fc_sel(cfg_fc_sel) enable((*inhigh*) EN_cfg_fc_sel);
        method flr_done(cfg_flr_done) enable((*inhigh*) EN_cfg_flr_done);
        method cfg_flr_in_process flr_in_process();
        method cfg_function_power_state function_power_state();
        method cfg_function_status function_status();
        method hot_reset_in(cfg_hot_reset_in) enable((*inhigh*) EN_cfg_hot_reset_in);
        method cfg_hot_reset_out hot_reset_out();
        method interrupt_int(cfg_interrupt_int) enable((*inhigh*) EN_cfg_interrupt_int);
        method interrupt_msi_attr(cfg_interrupt_msi_attr) enable((*inhigh*) EN_cfg_interrupt_msi_attr);
        method cfg_interrupt_msi_data interrupt_msi_data();
        method cfg_interrupt_msi_enable interrupt_msi_enable();
        method cfg_interrupt_msi_fail interrupt_msi_fail();
        method interrupt_msi_function_number(cfg_interrupt_msi_function_number) enable((*inhigh*) EN_cfg_interrupt_msi_function_number);
        method interrupt_msi_int(cfg_interrupt_msi_int) enable((*inhigh*) EN_cfg_interrupt_msi_int);
        method cfg_interrupt_msi_mask_update interrupt_msi_mask_update();
        method cfg_interrupt_msi_mmenable interrupt_msi_mmenable();
        method interrupt_msi_pending_status(cfg_interrupt_msi_pending_status) enable((*inhigh*) EN_cfg_interrupt_msi_pending_status);
        method interrupt_msi_select(cfg_interrupt_msi_select) enable((*inhigh*) EN_cfg_interrupt_msi_select);
        method cfg_interrupt_msi_sent interrupt_msi_sent();
        method interrupt_msi_tph_present(cfg_interrupt_msi_tph_present) enable((*inhigh*) EN_cfg_interrupt_msi_tph_present);
        method interrupt_msi_tph_st_tag(cfg_interrupt_msi_tph_st_tag) enable((*inhigh*) EN_cfg_interrupt_msi_tph_st_tag);
        method interrupt_msi_tph_type(cfg_interrupt_msi_tph_type) enable((*inhigh*) EN_cfg_interrupt_msi_tph_type);
        method cfg_interrupt_msi_vf_enable interrupt_msi_vf_enable();
        method interrupt_pending(cfg_interrupt_pending) enable((*inhigh*) EN_cfg_interrupt_pending);
        method cfg_interrupt_sent interrupt_sent();
        method cfg_link_power_state link_power_state();
        method link_training_enable(cfg_link_training_enable) enable((*inhigh*) EN_cfg_link_training_enable);
        method cfg_ltr_enable ltr_enable();
        method cfg_ltssm_state ltssm_state();
        method cfg_max_payload max_payload();
        method cfg_max_read_req max_read_req();
        method mgmt_addr(cfg_mgmt_addr) enable((*inhigh*) EN_cfg_mgmt_addr);
        method mgmt_byte_enable(cfg_mgmt_byte_enable) enable((*inhigh*) EN_cfg_mgmt_byte_enable);
        method mgmt_read(cfg_mgmt_read) enable((*inhigh*) EN_cfg_mgmt_read);
        method cfg_mgmt_read_data mgmt_read_data();
        method cfg_mgmt_read_write_done mgmt_read_write_done();
        method mgmt_write(cfg_mgmt_write) enable((*inhigh*) EN_cfg_mgmt_write);
        method mgmt_write_data(cfg_mgmt_write_data) enable((*inhigh*) EN_cfg_mgmt_write_data);
        method cfg_msg_received msg_received();
        method cfg_msg_received_data msg_received_data();
        method cfg_msg_received_type msg_received_type();
        method msg_transmit(cfg_msg_transmit) enable((*inhigh*) EN_cfg_msg_transmit);
        method msg_transmit_data(cfg_msg_transmit_data) enable((*inhigh*) EN_cfg_msg_transmit_data);
        method cfg_msg_transmit_done msg_transmit_done();
        method msg_transmit_type(cfg_msg_transmit_type) enable((*inhigh*) EN_cfg_msg_transmit_type);
        method cfg_negotiated_width negotiated_width();
        method cfg_obff_enable obff_enable();
        method per_func_status_control(cfg_per_func_status_control) enable((*inhigh*) EN_cfg_per_func_status_control);
        method cfg_per_func_status_data per_func_status_data();
        method per_function_number(cfg_per_function_number) enable((*inhigh*) EN_cfg_per_function_number);
        method per_function_output_request(cfg_per_function_output_request) enable((*inhigh*) EN_cfg_per_function_output_request);
        method cfg_per_function_update_done per_function_update_done();
        method cfg_phy_link_down phy_link_down();
        method cfg_phy_link_status phy_link_status();
        method cfg_pl_status_change pl_status_change();
        method power_state_change_ack(cfg_power_state_change_ack) enable((*inhigh*) EN_cfg_power_state_change_ack);
        method cfg_power_state_change_interrupt power_state_change_interrupt();
        method cfg_rcb_status rcb_status();
        method subsys_vend_id(cfg_subsys_vend_id) enable((*inhigh*) EN_cfg_subsys_vend_id);
        method cfg_tph_requester_enable tph_requester_enable();
        method cfg_tph_st_mode tph_st_mode();
        method vf_flr_done(cfg_vf_flr_done) enable((*inhigh*) EN_cfg_vf_flr_done);
        method cfg_vf_flr_in_process vf_flr_in_process();
        method cfg_vf_power_state vf_power_state();
        method cfg_vf_status vf_status();
        method cfg_vf_tph_requester_enable vf_tph_requester_enable();
        method cfg_vf_tph_st_mode vf_tph_st_mode();
    endinterface
    interface Pcie3wrapCfg_mgmt_type1     cfg_mgmt_type1;
        method cfg_reg_access(cfg_mgmt_type1_cfg_reg_access) enable((*inhigh*) EN_cfg_mgmt_type1_cfg_reg_access);
    endinterface
    interface Pcie3wrapCfg_req_pm_transition_l23     cfg_req_pm_transition_l23;
        method ready(cfg_req_pm_transition_l23_ready) enable((*inhigh*) EN_cfg_req_pm_transition_l23_ready);
    endinterface
    interface Pcie3wrapInt     int;
        method int_dclk_out dclk_out();
        method int_oobclk_out oobclk_out();
        method int_pclk_out_slave pclk_out_slave();
        method pclk_sel_slave(int_pclk_sel_slave) enable((*inhigh*) EN_int_pclk_sel_slave);
        method int_pipe_rxusrclk_out pipe_rxusrclk_out();
        method int_qplllock_out qplllock_out();
        method int_qplloutclk_out qplloutclk_out();
        method int_qplloutrefclk_out qplloutrefclk_out();
        method int_rxoutclk_out rxoutclk_out();
    endinterface
    interface Pcie3wrapInt_userclk1     int_userclk1;
        method int_userclk1_out out();
    endinterface
    interface Pcie3wrapInt_userclk2     int_userclk2;
        method int_userclk2_out out();
    endinterface
    interface Pcie3wrapM_axis_cq     m_axis_cq;
        method m_axis_cq_tdata tdata();
        method m_axis_cq_tkeep tkeep();
        method m_axis_cq_tlast tlast();
        method tready(m_axis_cq_tready) enable((*inhigh*) EN_m_axis_cq_tready);
        method m_axis_cq_tuser tuser();
        method m_axis_cq_tvalid tvalid();
    endinterface
    interface Pcie3wrapM_axis_rc     m_axis_rc;
        method m_axis_rc_tdata tdata();
        method m_axis_rc_tkeep tkeep();
        method m_axis_rc_tlast tlast();
        method tready(m_axis_rc_tready) enable((*inhigh*) EN_m_axis_rc_tready);
        method m_axis_rc_tuser tuser();
        method m_axis_rc_tvalid tvalid();
    endinterface
    interface Pcie3wrapPci     pci;
        method exp_rxn(pci_exp_rxn) enable((*inhigh*) EN_pci_exp_rxn);
        method exp_rxp(pci_exp_rxp) enable((*inhigh*) EN_pci_exp_rxp);
        method pci_exp_txn exp_txn();
        method pci_exp_txp exp_txp();
    endinterface
    interface Pcie3wrapPcie     pcie;
        method cq_np_req(pcie_cq_np_req) enable((*inhigh*) EN_pcie_cq_np_req);
        method pcie_cq_np_req_count cq_np_req_count();
        method pcie_rq_seq_num rq_seq_num();
        method pcie_rq_seq_num_vld rq_seq_num_vld();
        method pcie_rq_tag rq_tag();
        method pcie_rq_tag_vld rq_tag_vld();
        method pcie_tfc_npd_av tfc_npd_av();
        method pcie_tfc_nph_av tfc_nph_av();
    endinterface
    interface Pcie3wrapS_axis_cc     s_axis_cc;
        method tdata(s_axis_cc_tdata) enable((*inhigh*) EN_s_axis_cc_tdata);
        method tkeep(s_axis_cc_tkeep) enable((*inhigh*) EN_s_axis_cc_tkeep);
        method tlast(s_axis_cc_tlast) enable((*inhigh*) EN_s_axis_cc_tlast);
        method s_axis_cc_tready tready();
        method tuser(s_axis_cc_tuser) enable((*inhigh*) EN_s_axis_cc_tuser);
        method tvalid(s_axis_cc_tvalid) enable((*inhigh*) EN_s_axis_cc_tvalid);
    endinterface
    interface Pcie3wrapS_axis_rq     s_axis_rq;
        method tdata(s_axis_rq_tdata) enable((*inhigh*) EN_s_axis_rq_tdata);
        method tkeep(s_axis_rq_tkeep) enable((*inhigh*) EN_s_axis_rq_tkeep);
        method tlast(s_axis_rq_tlast) enable((*inhigh*) EN_s_axis_rq_tlast);
        method s_axis_rq_tready tready();
        method tuser(s_axis_rq_tuser) enable((*inhigh*) EN_s_axis_rq_tuser);
        method tvalid(s_axis_rq_tvalid) enable((*inhigh*) EN_s_axis_rq_tvalid);
    endinterface
    interface Pcie3wrapSys     sys;
        method clk(sys_clk) enable((*inhigh*) EN_sys_clk);
        method reset(sys_reset) enable((*inhigh*) EN_sys_reset);
    endinterface
    interface Pcie3wrapUser     user;
        method user_app_rdy app_rdy();
        method user_clk clk();
        method user_lnk_up lnk_up();
        method user_reset reset();
    endinterface
    schedule (cfg.config_space_enable, cfg.current_speed, cfg.dpa_substate_change, cfg.ds_bus_number, cfg.ds_device_number, cfg.ds_function_number, cfg.ds_port_number, cfg.dsn, cfg.err_cor_in, cfg.err_cor_out, cfg.err_fatal_out, cfg.err_nonfatal_out, cfg.err_uncor_in, cfg.ext_function_number, cfg.ext_read_data, cfg.ext_read_data_valid, cfg.ext_read_received, cfg.ext_register_number, cfg.ext_write_byte_enable, cfg.ext_write_data, cfg.ext_write_received, cfg.fc_cpld, cfg.fc_cplh, cfg.fc_npd, cfg.fc_nph, cfg.fc_pd, cfg.fc_ph, cfg.fc_sel, cfg.flr_done, cfg.flr_in_process, cfg.function_power_state, cfg.function_status, cfg.hot_reset_in, cfg.hot_reset_out, cfg.interrupt_int, cfg.interrupt_msi_attr, cfg.interrupt_msi_data, cfg.interrupt_msi_enable, cfg.interrupt_msi_fail, cfg.interrupt_msi_function_number, cfg.interrupt_msi_int, cfg.interrupt_msi_mask_update, cfg.interrupt_msi_mmenable, cfg.interrupt_msi_pending_status, cfg.interrupt_msi_select, cfg.interrupt_msi_sent, cfg.interrupt_msi_tph_present, cfg.interrupt_msi_tph_st_tag, cfg.interrupt_msi_tph_type, cfg.interrupt_msi_vf_enable, cfg.interrupt_pending, cfg.interrupt_sent, cfg.link_power_state, cfg.link_training_enable, cfg.ltr_enable, cfg.ltssm_state, cfg.max_payload, cfg.max_read_req, cfg.mgmt_addr, cfg.mgmt_byte_enable, cfg.mgmt_read, cfg.mgmt_read_data, cfg.mgmt_read_write_done, cfg.mgmt_write, cfg.mgmt_write_data, cfg.msg_received, cfg.msg_received_data, cfg.msg_received_type, cfg.msg_transmit, cfg.msg_transmit_data, cfg.msg_transmit_done, cfg.msg_transmit_type, cfg.negotiated_width, cfg.obff_enable, cfg.per_func_status_control, cfg.per_func_status_data, cfg.per_function_number, cfg.per_function_output_request, cfg.per_function_update_done, cfg.phy_link_down, cfg.phy_link_status, cfg.pl_status_change, cfg.power_state_change_ack, cfg.power_state_change_interrupt, cfg.rcb_status, cfg.subsys_vend_id, cfg.tph_requester_enable, cfg.tph_st_mode, cfg.vf_flr_done, cfg.vf_flr_in_process, cfg.vf_power_state, cfg.vf_status, cfg.vf_tph_requester_enable, cfg.vf_tph_st_mode, cfg_mgmt_type1.cfg_reg_access, cfg_req_pm_transition_l23.ready, int.dclk_out, int.oobclk_out, int.pclk_out_slave, int.pclk_sel_slave, int.pipe_rxusrclk_out, int.qplllock_out, int.qplloutclk_out, int.qplloutrefclk_out, int.rxoutclk_out, int_userclk1.out, int_userclk2.out, m_axis_cq.tdata, m_axis_cq.tkeep, m_axis_cq.tlast, m_axis_cq.tready, m_axis_cq.tuser, m_axis_cq.tvalid, m_axis_rc.tdata, m_axis_rc.tkeep, m_axis_rc.tlast, m_axis_rc.tready, m_axis_rc.tuser, m_axis_rc.tvalid, pci.exp_rxn, pci.exp_rxp, pci.exp_txn, pci.exp_txp, pcie.cq_np_req, pcie.cq_np_req_count, pcie.rq_seq_num, pcie.rq_seq_num_vld, pcie.rq_tag, pcie.rq_tag_vld, pcie.tfc_npd_av, pcie.tfc_nph_av, s_axis_cc.tdata, s_axis_cc.tkeep, s_axis_cc.tlast, s_axis_cc.tready, s_axis_cc.tuser, s_axis_cc.tvalid, s_axis_rq.tdata, s_axis_rq.tkeep, s_axis_rq.tlast, s_axis_rq.tready, s_axis_rq.tuser, s_axis_rq.tvalid, sys.clk, sys.reset, user.app_rdy, user.clk, user.lnk_up, user.reset) CF (cfg.config_space_enable, cfg.current_speed, cfg.dpa_substate_change, cfg.ds_bus_number, cfg.ds_device_number, cfg.ds_function_number, cfg.ds_port_number, cfg.dsn, cfg.err_cor_in, cfg.err_cor_out, cfg.err_fatal_out, cfg.err_nonfatal_out, cfg.err_uncor_in, cfg.ext_function_number, cfg.ext_read_data, cfg.ext_read_data_valid, cfg.ext_read_received, cfg.ext_register_number, cfg.ext_write_byte_enable, cfg.ext_write_data, cfg.ext_write_received, cfg.fc_cpld, cfg.fc_cplh, cfg.fc_npd, cfg.fc_nph, cfg.fc_pd, cfg.fc_ph, cfg.fc_sel, cfg.flr_done, cfg.flr_in_process, cfg.function_power_state, cfg.function_status, cfg.hot_reset_in, cfg.hot_reset_out, cfg.interrupt_int, cfg.interrupt_msi_attr, cfg.interrupt_msi_data, cfg.interrupt_msi_enable, cfg.interrupt_msi_fail, cfg.interrupt_msi_function_number, cfg.interrupt_msi_int, cfg.interrupt_msi_mask_update, cfg.interrupt_msi_mmenable, cfg.interrupt_msi_pending_status, cfg.interrupt_msi_select, cfg.interrupt_msi_sent, cfg.interrupt_msi_tph_present, cfg.interrupt_msi_tph_st_tag, cfg.interrupt_msi_tph_type, cfg.interrupt_msi_vf_enable, cfg.interrupt_pending, cfg.interrupt_sent, cfg.link_power_state, cfg.link_training_enable, cfg.ltr_enable, cfg.ltssm_state, cfg.max_payload, cfg.max_read_req, cfg.mgmt_addr, cfg.mgmt_byte_enable, cfg.mgmt_read, cfg.mgmt_read_data, cfg.mgmt_read_write_done, cfg.mgmt_write, cfg.mgmt_write_data, cfg.msg_received, cfg.msg_received_data, cfg.msg_received_type, cfg.msg_transmit, cfg.msg_transmit_data, cfg.msg_transmit_done, cfg.msg_transmit_type, cfg.negotiated_width, cfg.obff_enable, cfg.per_func_status_control, cfg.per_func_status_data, cfg.per_function_number, cfg.per_function_output_request, cfg.per_function_update_done, cfg.phy_link_down, cfg.phy_link_status, cfg.pl_status_change, cfg.power_state_change_ack, cfg.power_state_change_interrupt, cfg.rcb_status, cfg.subsys_vend_id, cfg.tph_requester_enable, cfg.tph_st_mode, cfg.vf_flr_done, cfg.vf_flr_in_process, cfg.vf_power_state, cfg.vf_status, cfg.vf_tph_requester_enable, cfg.vf_tph_st_mode, cfg_mgmt_type1.cfg_reg_access, cfg_req_pm_transition_l23.ready, int.dclk_out, int.oobclk_out, int.pclk_out_slave, int.pclk_sel_slave, int.pipe_rxusrclk_out, int.qplllock_out, int.qplloutclk_out, int.qplloutrefclk_out, int.rxoutclk_out, int_userclk1.out, int_userclk2.out, m_axis_cq.tdata, m_axis_cq.tkeep, m_axis_cq.tlast, m_axis_cq.tready, m_axis_cq.tuser, m_axis_cq.tvalid, m_axis_rc.tdata, m_axis_rc.tkeep, m_axis_rc.tlast, m_axis_rc.tready, m_axis_rc.tuser, m_axis_rc.tvalid, pci.exp_rxn, pci.exp_rxp, pci.exp_txn, pci.exp_txp, pcie.cq_np_req, pcie.cq_np_req_count, pcie.rq_seq_num, pcie.rq_seq_num_vld, pcie.rq_tag, pcie.rq_tag_vld, pcie.tfc_npd_av, pcie.tfc_nph_av, s_axis_cc.tdata, s_axis_cc.tkeep, s_axis_cc.tlast, s_axis_cc.tready, s_axis_cc.tuser, s_axis_cc.tvalid, s_axis_rq.tdata, s_axis_rq.tkeep, s_axis_rq.tlast, s_axis_rq.tready, s_axis_rq.tuser, s_axis_rq.tvalid, sys.clk, sys.reset, user.app_rdy, user.clk, user.lnk_up, user.reset);
endmodule
