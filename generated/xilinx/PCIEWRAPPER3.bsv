
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
    
    
    schedule (cfg.interrupt_int, cfg.interrupt_msix_address, cfg.interrupt_msix_data, cfg.interrupt_msix_enable, cfg.interrupt_msix_fail, cfg.interrupt_msix_int, cfg.interrupt_msix_mask, cfg.interrupt_msix_sent, cfg.interrupt_msix_vf_enable, cfg.interrupt_msix_vf_mask, cfg.interrupt_pending, cfg.interrupt_sent, common.commands_in, common.commands_out, int_pclk_sel.slave, int_qplllock.out, m_axis_cq.tdata, m_axis_cq.tkeep, m_axis_cq.tlast, m_axis_cq.tready, m_axis_cq.tuser, m_axis_cq.tvalid, m_axis_rc.tdata, m_axis_rc.tkeep, m_axis_rc.tlast, m_axis_rc.tready, m_axis_rc.tuser, m_axis_rc.tvalid, pci_exp.rxn, pci_exp.rxp, pci_exp.txn, pci_exp.txp, pipe.rx_0_sigs, pipe.rx_1_sigs, pipe.rx_2_sigs, pipe.rx_3_sigs, pipe.rx_4_sigs, pipe.rx_5_sigs, pipe.rx_6_sigs, pipe.rx_7_sigs, pipe.tx_0_sigs, pipe.tx_1_sigs, pipe.tx_2_sigs, pipe.tx_3_sigs, pipe.tx_4_sigs, pipe.tx_5_sigs, pipe.tx_6_sigs, pipe.tx_7_sigs, s_axis_cc.tdata, s_axis_cc.tkeep, s_axis_cc.tlast, s_axis_cc.tready, s_axis_cc.tuser, s_axis_cc.tvalid, s_axis_rq.tdata, s_axis_rq.tkeep, s_axis_rq.tlast, s_axis_rq.tready, s_axis_rq.tuser, s_axis_rq.tvalid, user.app_rdy, user.lnk_up) CF (cfg.interrupt_int, cfg.interrupt_msix_address, cfg.interrupt_msix_data, cfg.interrupt_msix_enable, cfg.interrupt_msix_fail, cfg.interrupt_msix_int, cfg.interrupt_msix_mask, cfg.interrupt_msix_sent, cfg.interrupt_msix_vf_enable, cfg.interrupt_msix_vf_mask, cfg.interrupt_pending, cfg.interrupt_sent, common.commands_in, common.commands_out, int_pclk_sel.slave, int_qplllock.out, m_axis_cq.tdata, m_axis_cq.tkeep, m_axis_cq.tlast, m_axis_cq.tready, m_axis_cq.tuser, m_axis_cq.tvalid, m_axis_rc.tdata, m_axis_rc.tkeep, m_axis_rc.tlast, m_axis_rc.tready, m_axis_rc.tuser, m_axis_rc.tvalid, pci_exp.rxn, pci_exp.rxp, pci_exp.txn, pci_exp.txp, pipe.rx_0_sigs, pipe.rx_1_sigs, pipe.rx_2_sigs, pipe.rx_3_sigs, pipe.rx_4_sigs, pipe.rx_5_sigs, pipe.rx_6_sigs, pipe.rx_7_sigs, pipe.tx_0_sigs, pipe.tx_1_sigs, pipe.tx_2_sigs, pipe.tx_3_sigs, pipe.tx_4_sigs, pipe.tx_5_sigs, pipe.tx_6_sigs, pipe.tx_7_sigs, s_axis_cc.tdata, s_axis_cc.tkeep, s_axis_cc.tlast, s_axis_cc.tready, s_axis_cc.tuser, s_axis_cc.tvalid, s_axis_rq.tdata, s_axis_rq.tkeep, s_axis_rq.tlast, s_axis_rq.tready, s_axis_rq.tuser, s_axis_rq.tvalid, user.app_rdy, user.lnk_up);
endmodule
