////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2012  Bluespec, Inc.  ALL RIGHTS RESERVED.
////////////////////////////////////////////////////////////////////////////////
//  Filename      : XbsvXilinx7PCIE.bsv
//  Description   : 
////////////////////////////////////////////////////////////////////////////////
package XbsvXilinx7Pcie;

// Notes :

////////////////////////////////////////////////////////////////////////////////
/// Imports
////////////////////////////////////////////////////////////////////////////////
import Clocks            ::*;
import Vector            ::*;
import Connectable       ::*;
import GetPut            ::*;
import Reserved          ::*;
import TieOff            ::*;
import DefaultValue      ::*;
import DReg              ::*;
import Gearbox           ::*;
import FIFO              ::*;
import FIFOF             ::*;
import SpecialFIFOs      ::*;

import XilinxCells       ::*;
import PCIE              ::*;

////////////////////////////////////////////////////////////////////////////////
/// Types
////////////////////////////////////////////////////////////////////////////////
typedef struct {
   Bit#(22)      user;
   Bool          last;
   Bit#(8)       keep;
   Bit#(64)      data;
} AxiRx deriving (Bits, Eq);

typedef struct {
   Bool          last;
   Bit#(8)       keep;
   Bit#(64)      data;
} AxiTx deriving (Bits, Eq);		

////////////////////////////////////////////////////////////////////////////////
/// Interfaces
////////////////////////////////////////////////////////////////////////////////
(* always_ready, always_enabled *)
interface PCIE_X7#(numeric type lanes);
   interface PCIE_EXP#(lanes) pcie;
   interface PCIE_TRN_X7      trn;
   interface PCIE_AXI_TX_X7   axi_tx;
   interface PCIE_AXI_RX_X7   axi_rx;
   interface PCIE_PL_X7       pl;
   interface PCIE_CFG_X7      cfg;
   interface PCIE_INT_X7      cfg_interrupt;
   interface PCIE_ERR_X7      cfg_err;
endinterface

(* always_ready, always_enabled *)
interface PCIE_TRN_X7;
   interface Clock            clk;
   interface Reset            reset;
   method    Bool             lnk_up;
   method    Bool             app_rdy;
   method    Bit#(8)          fc_ph;
   method    Bit#(12)         fc_pd;
   method    Bit#(8)          fc_nph;
   method    Bit#(12)         fc_npd;
   method    Bit#(8)          fc_cplh;
   method    Bit#(12)         fc_cpld;
   method    Action           fc_sel(FlowControlInfoSelect i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI_TX_X7;
   method    Action           tlast(Bool i);
   method    Action           tdata(Bit#(64) i);
   method    Action           tkeep(Bit#(8) i);
   method    Action           tvalid(Bool i);
   method    Bool             tready();
   method    Action           tuser(Bit#(4) i);
   method    Bit#(6)          tbuf_av();
   method    Bool             terr_drop();
   method    Bool             tcfg_req();
   method    Action           tcfg_gnt(Bool i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI_RX_X7;
   method    Bool             rlast();
   method    Bit#(64)         rdata();
   method    Bit#(8)          rkeep();
   method    Bit#(22)         ruser();
   method    Bool             rvalid();
   method    Action           rready(Bool i);
   method    Action           rnp_ok(Bool i);
   method    Action           rnp_req(Bool i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_PL_X7;
   method    Bit#(3)     initial_link_width;
   method    Bool        phy_link_up;
   method    Bit#(2)     lane_reversal_mode;
   method    Bit#(1)     link_gen2_capable;
   method    Bit#(1)     link_partner_gen2_supported;
   method    Bit#(1)     link_upcfg_capable;
   method    Bit#(1)     sel_link_rate;
   method    Bit#(2)     sel_link_width;
   method    Bit#(6)     ltssm_state;
   method    Bit#(2)     rx_pm_state;
   method    Bit#(3)     tx_pm_state;
   method    Action      directed_link_auton(Bit#(1) i);
   method    Action      directed_link_change(Bit#(2) i);
   method    Action      directed_link_speed(Bit#(1) i);
   method    Action      directed_link_width(Bit#(2) i);
   method    Bit#(1)     directed_change_done;
   method    Action      upstream_prefer_deemph(Bit#(1) i);
   method    Bit#(1)     received_hot_rst;   
endinterface

(* always_ready, always_enabled *)
interface PCIE_CFG_X7;
   method    Bit#(32)    dout;
   method    Bit#(1)     rd_wr_done;
   method    Action      di(Bit#(32) i);
   method    Action      dwaddr(Bit#(10) i);
   method    Action      byte_en(Bit#(4) i);
   method    Action      wr_en(Bit#(1) i);
   method    Action      rd_en(Bit#(1) i);
   method    Action      wr_readonly(Bit#(1) i);
   method    Bit#(8)     bus_number;
   method    Bit#(5)     device_number;
   method    Bit#(3)     function_number;
   method    Bit#(16)    status;
   method    Bit#(16)    command;
   method    Bit#(16)    dstatus;
   method    Bit#(16)    dcommand;
   method    Bit#(16)    dcommand2;
   method    Bit#(16)    lstatus;
   method    Bit#(16)    lcommand;
   method    Bit#(1)     aer_ecrc_gen_en;
   method    Bit#(1)     aer_ecrc_check_en;
   method    Bit#(3)     pcie_link_state;
   method    Action      trn_pending(Bit#(1) i);
   method    Action      dsn(Bit#(64) i);
   method    Bit#(1)     pmcsr_pme_en;
   method    Bit#(1)     pmcsr_pme_status;
   method    Bit#(2)     pmcsr_powerstate;
   method    Action      pm_halt_aspm_l0s(Bit#(1) i);
   method    Action      pm_halt_aspm_l1(Bit#(1) i);
   method    Action      pm_force_state(Bit#(2) i);
   method    Action      pm_force_state_en(Bit#(1) i);
   method    Bit#(1)     received_func_lvl_rst;
   method    Bit#(7)     vc_tcvc_map;
   method    Bit#(1)     to_turnoff;
   method    Action      turnoff_ok(Bit#(1) i);
   method    Action      pm_wake(Bit#(1) i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_INT_X7;
   method    Action      req(Bit#(1) i);
   method    Bit#(1)     rdy;
   method    Action      assrt(Bit#(1) i);
   method    Action      di(Bit#(8) i);
   method    Bit#(8)     dout;
   method    Bit#(3)     mmenable;
   method    Bit#(1)     msienable;
   method    Bit#(1)     msixenable;
   method    Bit#(1)     msixfm;
   method    Action      pciecap_msgnum(Bit#(5) i);
   method    Action      stat(Bit#(1) i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_ERR_X7;
   method    Action      ecrc(Bit#(1) i);
   method    Action      ur(Bit#(1) i);
   method    Action      cpl_timeout(Bit#(1) i);
   method    Action      cpl_unexpect(Bit#(1) i);
   method    Action      cpl_abort(Bit#(1) i);
   method    Action      posted(Bit#(1) i);
   method    Action      cor(Bit#(1) i);
   method    Action      atomic_egress_blocked(Bit#(1) i);
   method    Action      internal_cor(Bit#(1) i);
   method    Action      internal_uncor(Bit#(1) i);
   method    Action      malformed(Bit#(1) i);
   method    Action      mc_blocked(Bit#(1) i);
   method    Action      poisoned(Bit#(1) i);
   method    Action      no_recovery(Bit#(1) i);
   method    Action      tlp_cpl_header(Bit#(48) i);
   method    Bit#(1)     cpl_rdy;
   method    Action      locked(Bit#(1) i);
   method    Action      aer_headerlog(Bit#(128) i);
   method    Bit#(1)     aer_headerlog_set;
   method    Action      aer_interrupt_msgnum(Bit#(5) i);
   method    Action      acs(Bit#(1) i);
endinterface

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
///
/// Implementation
///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
import "BVI" xilinx_x7_pcie_wrapper =
module vMkXilinx7PCIExpress#(PCIEParams params)(PCIE_X7#(lanes))
   provisos( Add#(1, z, lanes));
   
`ifdef Artix7
   String gt_device = "GTP";
   Integer max_link_width = 4;
`else
   String gt_device = "GTX";
   Integer max_link_width = 8;
`endif

   // PCIe wrapper takes active low reset
   let sys_reset_n <- exposeCurrentReset;
   
   default_clock clk(sys_clk); // 100 MHz refclk
   default_reset rstn(sys_reset_n) = sys_reset_n;
   
   parameter PL_FAST_TRAIN = (params.fast_train_sim_only) ? "TRUE" : "FALSE";
   parameter PCIE_EXT_CLK  = "TRUE";
   parameter BAR0 = 32'hFFF00004;
   parameter BAR1 = 32'hFFFFFFFF;
   parameter BAR2 = 32'hFFF00004;
   parameter BAR3 = 32'hFFFFFFFF;
   parameter PCIE_GT_DEVICE = gt_device;
   parameter LINK_CAP_MAX_LINK_WIDTH = max_link_width;

   interface PCIE_EXP pcie;
      method                            rxp(pci_exp_rxp) enable((*inhigh*)en0)                              reset_by(no_reset);
      method                            rxn(pci_exp_rxn) enable((*inhigh*)en1)                              reset_by(no_reset);
      method pci_exp_txp                txp                                                                 reset_by(no_reset);
      method pci_exp_txn                txn                                                                 reset_by(no_reset);
   endinterface
   
   interface PCIE_TRN_X7 trn;
      output_clock                      clk(user_clk_out);
      output_reset                      reset(user_reset_out);
      method user_lnk_up                lnk_up                                                              clocked_by(no_clock) reset_by(no_reset); /* semi-static */
      method user_app_rdy               app_rdy                                                             clocked_by(no_clock) reset_by(no_reset);
      method fc_ph                      fc_ph                                                               clocked_by(trn_clk)  reset_by(no_reset);
      method fc_pd                      fc_pd                                                               clocked_by(trn_clk)  reset_by(no_reset);
      method fc_nph                     fc_nph                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method fc_npd                     fc_npd                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method fc_cplh                    fc_cplh                                                             clocked_by(trn_clk)  reset_by(no_reset);
      method fc_cpld                    fc_cpld                                                             clocked_by(trn_clk)  reset_by(no_reset);
      method                            fc_sel(fc_sel)                               enable((*inhigh*)en01) clocked_by(trn_clk)  reset_by(no_reset);      
   endinterface
   
   interface PCIE_AXI_TX_X7 axi_tx;
      method                            tlast(s_axis_tx_tlast)                       enable((*inhigh*)en02) clocked_by(trn_clk)  reset_by(no_reset);
      method                            tdata(s_axis_tx_tdata)                       enable((*inhigh*)en03) clocked_by(trn_clk)  reset_by(no_reset);
      method                            tkeep(s_axis_tx_tkeep)                       enable((*inhigh*)en04) clocked_by(trn_clk)  reset_by(no_reset);
      method                            tvalid(s_axis_tx_tvalid)                     enable((*inhigh*)en05) clocked_by(trn_clk)  reset_by(no_reset);
      method s_axis_tx_tready           tready                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method                            tuser(s_axis_tx_tuser)                       enable((*inhigh*)en06) clocked_by(trn_clk)  reset_by(no_reset);
      method tx_buf_av                  tbuf_av                                                             clocked_by(trn_clk)  reset_by(no_reset);
      method tx_err_drop                terr_drop                                                           clocked_by(trn_clk)  reset_by(no_reset);
      method tx_cfg_req                 tcfg_req                                                            clocked_by(trn_clk)  reset_by(no_reset);
      method                            tcfg_gnt(tx_cfg_gnt)                         enable((*inhigh*)en07) clocked_by(trn_clk)  reset_by(no_reset);
   endinterface
   
   interface PCIE_AXI_RX_X7 axi_rx;
      method m_axis_rx_tlast            rlast                                                               clocked_by(trn_clk)  reset_by(no_reset);
      method m_axis_rx_tdata            rdata                                                               clocked_by(trn_clk)  reset_by(no_reset);
      method m_axis_rx_tkeep            rkeep                                                               clocked_by(trn_clk)  reset_by(no_reset);
      method m_axis_rx_tuser            ruser                                                               clocked_by(trn_clk)  reset_by(no_reset);
      method m_axis_rx_tvalid           rvalid                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method                            rready(m_axis_rx_tready)                     enable((*inhigh*)en08) clocked_by(trn_clk)  reset_by(no_reset);
      method                            rnp_ok(rx_np_ok)                             enable((*inhigh*)en09) clocked_by(trn_clk)  reset_by(no_reset);
      method                            rnp_req(rx_np_req)                           enable((*inhigh*)en10) clocked_by(trn_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_PL_X7 pl;
      method pl_initial_link_width      initial_link_width                                                       clocked_by(trn_clk)  reset_by(no_reset);
      method pl_phy_lnk_up              phy_link_up                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method pl_lane_reversal_mode      lane_reversal_mode                                                       clocked_by(trn_clk)  reset_by(no_reset);
      method pl_link_gen2_cap           link_gen2_capable                                                        clocked_by(trn_clk)  reset_by(no_reset);
      method pl_link_partner_gen2_supported link_partner_gen2_supported                                          clocked_by(trn_clk)  reset_by(no_reset);
      method pl_link_upcfg_cap          link_upcfg_capable                                                       clocked_by(trn_clk)  reset_by(no_reset);
      method pl_sel_lnk_rate            sel_link_rate                                                            clocked_by(trn_clk)  reset_by(no_reset);
      method pl_sel_lnk_width           sel_link_width                                                           clocked_by(trn_clk)  reset_by(no_reset);
      method pl_ltssm_state             ltssm_state                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method pl_rx_pm_state             rx_pm_state                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method pl_tx_pm_state             tx_pm_state                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method                            directed_link_auton(pl_directed_link_auton)       enable((*inhigh*)en13) clocked_by(trn_clk)  reset_by(no_reset);
      method                            directed_link_change(pl_directed_link_change)     enable((*inhigh*)en14) clocked_by(trn_clk)  reset_by(no_reset);
      method                            directed_link_speed(pl_directed_link_speed)       enable((*inhigh*)en15) clocked_by(trn_clk)  reset_by(no_reset);
      method                            directed_link_width(pl_directed_link_width)       enable((*inhigh*)en16) clocked_by(trn_clk)  reset_by(no_reset);
      method pl_directed_change_done    directed_change_done                                                     clocked_by(trn_clk)  reset_by(no_reset);
      method                            upstream_prefer_deemph(pl_upstream_prefer_deemph) enable((*inhigh*)en17) clocked_by(trn_clk)  reset_by(no_reset);
      method pl_received_hot_rst        received_hot_rst                                                         clocked_by(trn_clk)  reset_by(no_reset);
   endinterface
   
   interface PCIE_CFG_X7 cfg;
      method cfg_mgmt_do                dout                                                                     clocked_by(trn_clk) reset_by(no_reset);
      method cfg_mgmt_rd_wr_done        rd_wr_done                                                               clocked_by(trn_clk) reset_by(no_reset);
      method                            di(cfg_mgmt_di)                                   enable((*inhigh*)en18) clocked_by(trn_clk) reset_by(no_reset);
      method                            dwaddr(cfg_mgmt_dwaddr)                           enable((*inhigh*)en19) clocked_by(trn_clk) reset_by(no_reset);
      method                            byte_en(cfg_mgmt_byte_en)                         enable((*inhigh*)en20) clocked_by(trn_clk) reset_by(no_reset);
      method                            wr_en(cfg_mgmt_wr_en)                             enable((*inhigh*)en21) clocked_by(trn_clk) reset_by(no_reset);
      method                            rd_en(cfg_mgmt_rd_en)                             enable((*inhigh*)en22) clocked_by(trn_clk) reset_by(no_reset);
      method                            wr_readonly(cfg_mgmt_wr_readonly)                 enable((*inhigh*)en23) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_bus_number             bus_number                                                               clocked_by(no_clock) reset_by(no_reset);
      method cfg_device_number          device_number                                                            clocked_by(no_clock) reset_by(no_reset);
      method cfg_function_number        function_number                                                          clocked_by(no_clock) reset_by(no_reset);
      method cfg_status                 status                                                                   clocked_by(trn_clk) reset_by(no_reset);
      method cfg_command                command                                                                  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_dstatus                dstatus                                                                  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_dcommand               dcommand                                                                 clocked_by(trn_clk) reset_by(no_reset);
      method cfg_dcommand2              dcommand2                                                                clocked_by(trn_clk) reset_by(no_reset);
      method cfg_lstatus                lstatus                                                                  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_lcommand               lcommand                                                                 clocked_by(trn_clk) reset_by(no_reset);
      method cfg_aer_ecrc_gen_en        aer_ecrc_gen_en                                                          clocked_by(trn_clk) reset_by(no_reset);
      method cfg_aer_ecrc_check_en      aer_ecrc_check_en                                                        clocked_by(trn_clk) reset_by(no_reset);
      method cfg_pcie_link_state        pcie_link_state                                                          clocked_by(trn_clk) reset_by(no_reset);
      method                            trn_pending(cfg_trn_pending)                      enable((*inhigh*)en24) clocked_by(trn_clk) reset_by(no_reset);
      method                            dsn(cfg_dsn)                                      enable((*inhigh*)en25) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_pmcsr_pme_en           pmcsr_pme_en                                                             clocked_by(trn_clk) reset_by(no_reset);
      method cfg_pmcsr_pme_status       pmcsr_pme_status                                                         clocked_by(trn_clk) reset_by(no_reset);
      method cfg_pmcsr_powerstate       pmcsr_powerstate                                                         clocked_by(trn_clk) reset_by(no_reset);
      method                            pm_halt_aspm_l0s(cfg_pm_halt_aspm_l0s)            enable((*inhigh*)en26) clocked_by(trn_clk) reset_by(no_reset);
      method                            pm_halt_aspm_l1(cfg_pm_halt_aspm_l1)              enable((*inhigh*)en27) clocked_by(trn_clk) reset_by(no_reset);
      method                            pm_force_state(cfg_pm_force_state)                enable((*inhigh*)en28) clocked_by(trn_clk) reset_by(no_reset);
      method                            pm_force_state_en(cfg_pm_force_state_en)          enable((*inhigh*)en29) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_received_func_lvl_rst  received_func_lvl_rst                                                    clocked_by(trn_clk) reset_by(no_reset);
      method cfg_vc_tcvc_map            vc_tcvc_map                                                              clocked_by(trn_clk) reset_by(no_reset);
      method cfg_to_turnoff             to_turnoff                                                               clocked_by(trn_clk) reset_by(no_reset);
      method                            turnoff_ok(cfg_turnoff_ok)                        enable((*inhigh*)en30) clocked_by(trn_clk) reset_by(no_reset);
      method                            pm_wake(cfg_pm_wake)                              enable((*inhigh*)en31) clocked_by(trn_clk) reset_by(no_reset);
   endinterface

   interface PCIE_INT_X7 cfg_interrupt;
      method                            req(cfg_interrupt)                                enable((*inhigh*)en32) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_rdy          rdy                                                                      clocked_by(trn_clk) reset_by(no_reset);
      method                            assrt(cfg_interrupt_assert)                       enable((*inhigh*)en33) clocked_by(trn_clk) reset_by(no_reset);
      method                            di(cfg_interrupt_di)                              enable((*inhigh*)en34) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_do           dout                                                                     clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_mmenable     mmenable                                                                 clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_msienable    msienable                                                                clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_msixenable   msixenable                                                               clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_msixfm       msixfm                                                                   clocked_by(trn_clk) reset_by(no_reset);
      method                            pciecap_msgnum(cfg_pciecap_interrupt_msgnum)      enable((*inhigh*)en35) clocked_by(trn_clk) reset_by(no_reset);
      method                            stat(cfg_interrupt_stat)                          enable((*inhigh*)en36) clocked_by(trn_clk) reset_by(no_reset);
   endinterface
      
   interface PCIE_ERR_X7 cfg_err;
      method                            ecrc(cfg_err_ecrc)                           	  enable((*inhigh*)en37) clocked_by(trn_clk) reset_by(no_reset);
      method                            ur(cfg_err_ur)                               	  enable((*inhigh*)en38) clocked_by(trn_clk) reset_by(no_reset);
      method                            cpl_timeout(cfg_err_cpl_timeout)             	  enable((*inhigh*)en39) clocked_by(trn_clk) reset_by(no_reset);
      method                            cpl_unexpect(cfg_err_cpl_unexpect)           	  enable((*inhigh*)en40) clocked_by(trn_clk) reset_by(no_reset);
      method                            cpl_abort(cfg_err_cpl_abort)                 	  enable((*inhigh*)en41) clocked_by(trn_clk) reset_by(no_reset);
      method                            posted(cfg_err_posted)                       	  enable((*inhigh*)en42) clocked_by(trn_clk) reset_by(no_reset);
      method                            cor(cfg_err_cor)                             	  enable((*inhigh*)en43) clocked_by(trn_clk) reset_by(no_reset);
      method          			atomic_egress_blocked(cfg_err_atomic_egress_blocked) enable((*inhigh*)en44) clocked_by(trn_clk) reset_by(no_reset);
      method          			internal_cor(cfg_err_internal_cor)           	  enable((*inhigh*)en45) clocked_by(trn_clk) reset_by(no_reset);
      method          			internal_uncor(cfg_err_internal_uncor)       	  enable((*inhigh*)en46) clocked_by(trn_clk) reset_by(no_reset);
      method          			malformed(cfg_err_malformed)                 	  enable((*inhigh*)en47) clocked_by(trn_clk) reset_by(no_reset);
      method          			mc_blocked(cfg_err_mc_blocked)               	  enable((*inhigh*)en48) clocked_by(trn_clk) reset_by(no_reset);
      method          			poisoned(cfg_err_poisoned)                   	  enable((*inhigh*)en49) clocked_by(trn_clk) reset_by(no_reset);
      method          			no_recovery(cfg_err_norecovery)             	  enable((*inhigh*)en50) clocked_by(trn_clk) reset_by(no_reset);
      method                            tlp_cpl_header(cfg_err_tlp_cpl_header)       	  enable((*inhigh*)en51) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_err_cpl_rdy            cpl_rdy                                      	                         clocked_by(trn_clk) reset_by(no_reset);
      method                            locked(cfg_err_locked)                       	  enable((*inhigh*)en52) clocked_by(trn_clk) reset_by(no_reset);
      method         			aer_headerlog(cfg_err_aer_headerlog)         	  enable((*inhigh*)en53) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_err_aer_headerlog_set  aer_headerlog_set                                                        clocked_by(trn_clk) reset_by(no_reset);
      method         			aer_interrupt_msgnum(cfg_aer_interrupt_msgnum)    enable((*inhigh*)en54) clocked_by(trn_clk) reset_by(no_reset);
      method         			acs(cfg_err_acs)                                  enable((*inhigh*)en55) clocked_by(trn_clk) reset_by(no_reset);
   endinterface
      
   schedule (trn_lnk_up, trn_app_rdy, trn_fc_ph, trn_fc_pd, trn_fc_nph, trn_fc_npd, trn_fc_cplh, trn_fc_cpld, trn_fc_sel, axi_tx_tlast,
	     axi_tx_tdata, axi_tx_tkeep, axi_tx_tvalid, axi_tx_tready, axi_tx_tuser, axi_tx_tbuf_av, axi_tx_terr_drop,
	     axi_tx_tcfg_req, axi_tx_tcfg_gnt, axi_rx_rlast, axi_rx_rdata, axi_rx_rkeep, axi_rx_ruser, axi_rx_rvalid,
	     axi_rx_rready, axi_rx_rnp_ok, axi_rx_rnp_req, pl_initial_link_width, pl_phy_link_up, pl_lane_reversal_mode,
	     pl_link_gen2_capable, pl_link_partner_gen2_supported, pl_link_upcfg_capable, pl_sel_link_rate, pl_sel_link_width,
	     pl_ltssm_state, pl_rx_pm_state, pl_tx_pm_state, pl_directed_link_auton, pl_directed_link_change, 
	     pl_directed_link_speed, pl_directed_link_width, pl_directed_change_done, pl_upstream_prefer_deemph, 
	     pl_received_hot_rst, cfg_dout, cfg_rd_wr_done, cfg_di, cfg_dwaddr, cfg_byte_en, cfg_wr_en, cfg_rd_en, 
	     cfg_wr_readonly, cfg_bus_number, cfg_device_number, cfg_function_number, cfg_status, cfg_command, cfg_dstatus,
	     cfg_dcommand, cfg_dcommand2, cfg_lstatus, cfg_lcommand, cfg_aer_ecrc_gen_en, cfg_aer_ecrc_check_en,
	     cfg_pcie_link_state, cfg_trn_pending, cfg_dsn, cfg_pmcsr_pme_en, cfg_pmcsr_pme_status, cfg_pmcsr_powerstate,
	     cfg_pm_halt_aspm_l0s, cfg_pm_halt_aspm_l1, cfg_pm_force_state, cfg_pm_force_state_en, cfg_received_func_lvl_rst,
	     cfg_vc_tcvc_map, cfg_to_turnoff, cfg_turnoff_ok, cfg_pm_wake, 
	     cfg_interrupt_req, cfg_interrupt_rdy,
	     cfg_interrupt_assrt, cfg_interrupt_di, cfg_interrupt_dout, cfg_interrupt_mmenable, cfg_interrupt_msienable,
	     cfg_interrupt_msixenable, cfg_interrupt_msixfm, cfg_interrupt_pciecap_msgnum, cfg_interrupt_stat,
	     cfg_err_ecrc, cfg_err_ur, cfg_err_cpl_timeout, cfg_err_cpl_unexpect, cfg_err_cpl_abort, cfg_err_posted,
	     cfg_err_cor, cfg_err_atomic_egress_blocked, cfg_err_internal_cor, cfg_err_internal_uncor, cfg_err_malformed,
	     cfg_err_mc_blocked, cfg_err_poisoned, cfg_err_no_recovery, cfg_err_tlp_cpl_header, cfg_err_cpl_rdy, cfg_err_locked,
	     cfg_err_aer_headerlog, cfg_err_aer_headerlog_set, cfg_err_aer_interrupt_msgnum, cfg_err_acs,
	     pcie_txp, pcie_txn, pcie_rxp, pcie_rxn
	     ) CF 
            (trn_lnk_up, trn_app_rdy, trn_fc_ph, trn_fc_pd, trn_fc_nph, trn_fc_npd, trn_fc_cplh, trn_fc_cpld, trn_fc_sel, axi_tx_tlast,
	     axi_tx_tdata, axi_tx_tkeep, axi_tx_tvalid, axi_tx_tready, axi_tx_tuser, axi_tx_tbuf_av, axi_tx_terr_drop,
	     axi_tx_tcfg_req, axi_tx_tcfg_gnt, axi_rx_rlast, axi_rx_rdata, axi_rx_rkeep, axi_rx_ruser, axi_rx_rvalid,
	     axi_rx_rready, axi_rx_rnp_ok, axi_rx_rnp_req, pl_initial_link_width, pl_phy_link_up, pl_lane_reversal_mode,
	     pl_link_gen2_capable, pl_link_partner_gen2_supported, pl_link_upcfg_capable, pl_sel_link_rate, pl_sel_link_width,
	     pl_ltssm_state, pl_rx_pm_state, pl_tx_pm_state, pl_directed_link_auton, pl_directed_link_change, 
	     pl_directed_link_speed, pl_directed_link_width, pl_directed_change_done, pl_upstream_prefer_deemph, 
	     pl_received_hot_rst, cfg_dout, cfg_rd_wr_done, cfg_di, cfg_dwaddr, cfg_byte_en, cfg_wr_en, cfg_rd_en, 
	     cfg_wr_readonly, cfg_bus_number, cfg_device_number, cfg_function_number, cfg_status, cfg_command, cfg_dstatus,
	     cfg_dcommand, cfg_dcommand2, cfg_lstatus, cfg_lcommand, cfg_aer_ecrc_gen_en, cfg_aer_ecrc_check_en,
	     cfg_pcie_link_state, cfg_trn_pending, cfg_dsn, cfg_pmcsr_pme_en, cfg_pmcsr_pme_status, cfg_pmcsr_powerstate,
	     cfg_pm_halt_aspm_l0s, cfg_pm_halt_aspm_l1, cfg_pm_force_state, cfg_pm_force_state_en, cfg_received_func_lvl_rst,
	     cfg_vc_tcvc_map, cfg_to_turnoff, cfg_turnoff_ok, cfg_pm_wake, 
	     cfg_interrupt_req, cfg_interrupt_rdy,
	     cfg_interrupt_assrt, cfg_interrupt_di, cfg_interrupt_dout, cfg_interrupt_mmenable, cfg_interrupt_msienable,
	     cfg_interrupt_msixenable, cfg_interrupt_msixfm, cfg_interrupt_pciecap_msgnum, cfg_interrupt_stat,
	     cfg_err_ecrc, cfg_err_ur, cfg_err_cpl_timeout, cfg_err_cpl_unexpect, cfg_err_cpl_abort, cfg_err_posted,
	     cfg_err_cor, cfg_err_atomic_egress_blocked, cfg_err_internal_cor, cfg_err_internal_uncor, cfg_err_malformed,
	     cfg_err_mc_blocked, cfg_err_poisoned, cfg_err_no_recovery, cfg_err_tlp_cpl_header, cfg_err_cpl_rdy, cfg_err_locked,
	     cfg_err_aer_headerlog, cfg_err_aer_headerlog_set, cfg_err_aer_interrupt_msgnum, cfg_err_acs,
	     pcie_txp, pcie_txn, pcie_rxp, pcie_rxn
             );

endmodule: vMkXilinx7PCIExpress

////////////////////////////////////////////////////////////////////////////////
/// Interfaces
////////////////////////////////////////////////////////////////////////////////
interface PCIE_TRN_COMMON_X7;
   interface Clock       clk;
   interface Clock       clk2;
   interface Clock       clk3;
   interface Reset       reset_n;
   method    Bool        link_up;
   method    Bool        app_ready;
endinterface
    
interface PCIE_TRN_XMIT_X7;
   method    Action      xmit(TLPData#(8) data);
   method    Action      discontinue(Bool i);
   method    Action      ecrc_generate(Bool i);
   method    Action      error_forward(Bool i);
   method    Action      cut_through_mode(Bool i);
   method    Bool        dropped;
   method    Bit#(6)     buffers_available;
   method    Bool        configuration_completion_request;
   method    Action      configuration_completion_grant(Bool i);
endinterface

interface PCIE_TRN_RECV_X7;
   method    ActionValue#(Tuple3#(Bool, Bool, TLPData#(8))) recv();
   method    Action      non_posted_ok(Bool i);
   method    Action      non_posted_req(Bool i);
endinterface

interface PCIExpressX7#(numeric type lanes);
   interface PCIE_EXP#(lanes)   pcie;
   interface PCIE_TRN_COMMON_X7 trn;
   interface PCIE_TRN_XMIT_X7   trn_tx;
   interface PCIE_TRN_RECV_X7   trn_rx;
   interface PCIE_CFG_X7        cfg;
   interface PCIE_INT_X7        cfg_interrupt;
   interface PCIE_ERR_X7        cfg_err;
   interface PCIE_PL_X7         pl;
endinterface   

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
///
/// Implementation
///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
typeclass SelectXilinx7PCIE#(numeric type lanes);
   module selectXilinx7PCIE(PCIEParams params, PCIE_X7#(lanes) ifc);
endtypeclass

instance SelectXilinx7PCIE#(8);
   module selectXilinx7PCIE(PCIEParams params, PCIE_X7#(8) ifc);
      let _ifc <- vMkXilinx7PCIExpress(params);
      return _ifc;
   endmodule
endinstance

instance SelectXilinx7PCIE#(4);
   module selectXilinx7PCIE(PCIEParams params, PCIE_X7#(4) ifc);
      let _ifc <- vMkXilinx7PCIExpress(params);
      return _ifc;
   endmodule
endinstance

instance SelectXilinx7PCIE#(1);
   module selectXilinx7PCIE(PCIEParams params, PCIE_X7#(1) ifc);
      let _ifc <- vMkXilinx7PCIExpress(params);
      return _ifc;
   endmodule
endinstance

module mkPCIExpressEndpointX7#(PCIEParams params)(PCIExpressX7#(lanes))
   provisos(Add#(1, z, lanes), SelectXilinx7PCIE#(lanes));
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   PCIE_X7#(lanes)                           pcie_ep             <- selectXilinx7PCIE(params);

   Clock                                     user_clk             = pcie_ep.trn.clk;
   Reset                                     user_reset_n        <- mkResetInverter(pcie_ep.trn.reset);
   
   Wire#(Bit#(1))                            wDiscontinue        <- mkDWire(0, clocked_by user_clk, reset_by noReset);
   Wire#(Bit#(1))                            wEcrcGen            <- mkDWire(0, clocked_by user_clk, reset_by noReset);
   Wire#(Bit#(1))                            wErrFwd             <- mkDWire(0, clocked_by user_clk, reset_by noReset);
   Wire#(Bit#(1))                            wCutThrough         <- mkDWire(0, clocked_by user_clk, reset_by noReset);

   Wire#(Bool)                               wAxiTxValid         <- mkDWire(False, clocked_by user_clk, reset_by noReset);
   Wire#(Bool)                               wAxiTxLast          <- mkDWire(False, clocked_by user_clk, reset_by noReset);
   Wire#(Bit#(64))                           wAxiTxData          <- mkDWire(0, clocked_by user_clk, reset_by noReset);
   Wire#(Bit#(8))                            wAxiTxKeep          <- mkDWire(0, clocked_by user_clk, reset_by noReset);
   FIFO#(AxiTx)                              fAxiTx              <- mkBypassFIFO(clocked_by user_clk, reset_by noReset);
   
   FIFOF#(AxiRx)                             fAxiRx              <- mkBypassFIFOF(clocked_by user_clk, reset_by noReset);
   Wire#(Bool)                               wAxiRxReady         <- mkDWire(False, clocked_by user_clk, reset_by noReset);
   
   ClockGenerator7Params                     params               = defaultValue;
   params.clkin1_period    = 4.000;
   params.clkin_buffer     = False;
   params.clkfbout_mult_f  = 4.000;
   params.clkout0_divide_f = 8.000;
   params.clkout1_divide   = 16;
   ClockGenerator7                           clkgen              <- mkClockGenerator7(params, clocked_by user_clk, reset_by user_reset_n);
   Clock                                     user_clk_half        = clkgen.clkout0;
   Clock                                     user_clk_quarter     = clkgen.clkout1;
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Rules
   ////////////////////////////////////////////////////////////////////////////////
   (* fire_when_enabled, no_implicit_conditions *)
   rule others;
      pcie_ep.trn.fc_sel(RECEIVE_BUFFER_AVAILABLE_SPACE);
   endrule
   
   (* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_tx;
      pcie_ep.axi_tx.tuser({ wDiscontinue, wCutThrough, wErrFwd, wEcrcGen });
      pcie_ep.axi_tx.tvalid(wAxiTxValid);
      pcie_ep.axi_tx.tlast(wAxiTxLast);
      pcie_ep.axi_tx.tdata(wAxiTxData);
      pcie_ep.axi_tx.tkeep(wAxiTxKeep);
   endrule
   
   (* fire_when_enabled *)
   rule drive_axi_tx_info if (pcie_ep.axi_tx.tready);
      let info <- toGet(fAxiTx).get;
      wAxiTxValid <= True;
      wAxiTxLast  <= info.last;
      wAxiTxData  <= info.data;
      wAxiTxKeep  <= info.keep;
   endrule
   
   (* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_rx_ready;
      pcie_ep.axi_rx.rready(fAxiRx.notFull);
   endrule
   
   (* fire_when_enabled *)
   rule sink_axi_rx if (pcie_ep.axi_rx.rvalid);
      let info = AxiRx {
	 user:    pcie_ep.axi_rx.ruser,
	 last:    pcie_ep.axi_rx.rlast,
	 keep:    pcie_ep.axi_rx.rkeep,
	 data:    pcie_ep.axi_rx.rdata
	 };
      fAxiRx.enq(info);
   endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface pcie = pcie_ep.pcie;
      
   interface PCIE_TRN_COMMON_X7 trn;
      interface clk     = user_clk;
      interface clk2    = user_clk_half;
      interface clk3    = user_clk_quarter;
      interface reset_n = user_reset_n;
      method    link_up = pcie_ep.trn.lnk_up;
      method    app_ready = pcie_ep.trn.app_rdy;
   endinterface
      
   interface PCIE_TRN_XMIT_X7 trn_tx;
      method Action xmit(data);
	 fAxiTx.enq(AxiTx { last: data.eof, keep: dwordSwap64BE(data.be), data: dwordSwap64(data.data) });
      endmethod
      method discontinue(i)                    = wDiscontinue._write(pack(i));
      method ecrc_generate(i)          	       = wEcrcGen._write(pack(i));
      method error_forward(i)          	       = wErrFwd._write(pack(i));
      method cut_through_mode(i)       	       = wCutThrough._write(pack(i));
      method dropped                   	       = pcie_ep.axi_tx.terr_drop;
      method buffers_available         	       = pcie_ep.axi_tx.tbuf_av;
      method configuration_completion_request  = pcie_ep.axi_tx.tcfg_req;
      method configuration_completion_grant(i) = pcie_ep.axi_tx.tcfg_gnt(i);
   endinterface
      
   interface PCIE_TRN_RECV_X7 trn_rx;
      method ActionValue#(Tuple3#(Bool, Bool, TLPData#(8))) recv();
	 let info <- toGet(fAxiRx).get;
	 TLPData#(8) retval = defaultValue;
	 retval.sof  = (info.user[14] == 1);
	 retval.eof  = info.last;
	 retval.hit  = info.user[8:2];
	 retval.be   = dwordSwap64BE(info.keep);
	 retval.data = dwordSwap64(info.data);
	 return tuple3(info.user[1] == 1, info.user[0] == 1, retval);
      endmethod
      method non_posted_ok(i)  = pcie_ep.axi_rx.rnp_ok(i);
      method non_posted_req(i) = pcie_ep.axi_rx.rnp_req(i);
   endinterface
      
   interface pl = pcie_ep.pl;
   interface cfg = pcie_ep.cfg;
   interface cfg_interrupt = pcie_ep.cfg_interrupt;
   interface cfg_err = pcie_ep.cfg_err;
endmodule: mkPCIExpressEndpointX7

////////////////////////////////////////////////////////////////////////////////
/// Connection Instances
////////////////////////////////////////////////////////////////////////////////

// Basic TLPData#(8) connections to PCIE endpoint
instance Connectable#(Get#(TLPData#(8)), PCIE_TRN_XMIT_X7);
   module mkConnection#(Get#(TLPData#(8)) g, PCIE_TRN_XMIT_X7 p)(Empty);
      rule every;
         p.cut_through_mode(False);
         p.configuration_completion_grant(True);  // Core gets to choose
         p.error_forward(False);
	 p.ecrc_generate(False);
	 p.discontinue(False);
      endrule
      rule connect;
         let data <- g.get;
         p.xmit(data);
      endrule
   endmodule
endinstance

instance Connectable#(PCIE_TRN_XMIT_X7, Get#(TLPData#(8)));
   module mkConnection#(PCIE_TRN_XMIT_X7 p, Get#(TLPData#(8)) g)(Empty);
      mkConnection(g, p);
   endmodule
endinstance

instance Connectable#(Put#(TLPData#(8)), PCIE_TRN_RECV_X7);
   module mkConnection#(Put#(TLPData#(8)) p, PCIE_TRN_RECV_X7 r)(Empty);
      (* no_implicit_conditions, fire_when_enabled *)
      rule every;
         r.non_posted_ok(True);
	 r.non_posted_req(True);
      endrule
      rule connect;
         let data <- r.recv;
         p.put(tpl_3(data));
      endrule
   endmodule
endinstance

instance Connectable#(PCIE_TRN_RECV_X7, Put#(TLPData#(8)));
   module mkConnection#(PCIE_TRN_RECV_X7 r, Put#(TLPData#(8)) p)(Empty);
      mkConnection(p, r);
   endmodule
endinstance

// Connections between TLPData#(16) and a PCIE endpoint.
// These are all using the same clock, so the TLPData#(16) accesses
// will not be back-to-back.

instance Connectable#(Get#(TLPData#(16)), PCIE_TRN_XMIT_X7);
   module mkConnection#(Get#(TLPData#(16)) g, PCIE_TRN_XMIT_X7 t)(Empty);
      FIFO#(TLPData#(8)) outFifo <- mkFIFO();

      (* no_implicit_conditions, fire_when_enabled *)
      rule every;
         t.cut_through_mode(False);
         t.configuration_completion_grant(True);  // True means core gets to choose
         t.error_forward(False);
	 t.ecrc_generate(False);
	 t.discontinue(False);
      endrule

      rule connect;
         let data = outFifo.first; outFifo.deq;
         if (data.be != 0)
            t.xmit(data);
      endrule

      Put#(TLPData#(8)) p = fifoToPut(outFifo);
      mkConnection(g,p);
   endmodule
endinstance

instance Connectable#(PCIE_TRN_XMIT_X7, Get#(TLPData#(16)));
   module mkConnection#(PCIE_TRN_XMIT_X7 p, Get#(TLPData#(16)) g)(Empty);
      mkConnection(g, p);
   endmodule
endinstance

instance Connectable#(Put#(TLPData#(16)), PCIE_TRN_RECV_X7);
   module mkConnection#(Put#(TLPData#(16)) p, PCIE_TRN_RECV_X7 r)(Empty);
      FIFO#(TLPData#(8)) inFifo <- mkFIFO();

      (* no_implicit_conditions, fire_when_enabled *)
      rule every;
         r.non_posted_ok(True);
	 r.non_posted_req(True);
      endrule

      rule connect;
         let data <- r.recv;
         inFifo.enq(tpl_3(data));
      endrule

      Get#(TLPData#(8)) g = fifoToGet(inFifo);
      mkConnection(g,p);
   endmodule
endinstance

instance Connectable#(PCIE_TRN_RECV_X7, Put#(TLPData#(16)));
   module mkConnection#(PCIE_TRN_RECV_X7 r, Put#(TLPData#(16)) p)(Empty);
      mkConnection(p, r);
   endmodule
endinstance

// Connections between TLPData#(16) and a PCIE endpoint, using a gearbox
// to match data rates between the endpoint and design clocks.

instance ConnectableWithClocks#(PCIE_TRN_XMIT_X7, Get#(TLPData#(16)));
   module mkConnectionWithClocks#(PCIE_TRN_XMIT_X7 p, Get#(TLPData#(16)) g,
                                  Clock fastClock, Reset fastReset,
                                  Clock slowClock, Reset slowReset)(Empty);

      ////////////////////////////////////////////////////////////////////////////////
      /// Design Elements
      ////////////////////////////////////////////////////////////////////////////////
      FIFO#(TLPData#(8))                     outFifo             <- mkFIFO(clocked_by fastClock, reset_by fastReset);
      Gearbox#(2, 1, TLPData#(8))            fifoTxData          <- mkNto1Gearbox(slowClock, slowReset, fastClock, fastReset);

      ////////////////////////////////////////////////////////////////////////////////
      /// Rules
      ////////////////////////////////////////////////////////////////////////////////
      (* no_implicit_conditions, fire_when_enabled *)
      rule every;
         p.cut_through_mode(False);
         p.configuration_completion_grant(True);  // Means the core gets to choose
         p.error_forward(False);
	 p.ecrc_generate(False);
	 p.discontinue(False);
      endrule

      rule get_data;
         function Vector#(2, TLPData#(8)) split(TLPData#(16) in);
            Vector#(2, TLPData#(8)) v = defaultValue;
            v[0].sof  = in.sof;
            v[0].eof  = (in.be[7:0] == 0) ? in.eof : False;
            v[0].hit  = in.hit;
            v[0].be   = in.be[15:8];
            v[0].data = in.data[127:64];
            v[1].sof  = False;
            v[1].eof  = in.eof;
            v[1].hit  = in.hit;
            v[1].be   = in.be[7:0];
            v[1].data = in.data[63:0];
            return v;
         endfunction

         let data <- g.get;
         fifoTxData.enq(split(data));
      endrule

      rule process_outgoing_packets;
         let data = fifoTxData.first; fifoTxData.deq;
         outFifo.enq(head(data));
      endrule

      rule send_data;
         let data = outFifo.first; outFifo.deq;
         // filter out TLPs with 00 byte enable
         if (data.be != 0)
            p.xmit(data);
      endrule

   endmodule
endinstance

instance ConnectableWithClocks#(Get#(TLPData#(16)), PCIE_TRN_XMIT_X7);
   module mkConnectionWithClocks#(Get#(TLPData#(16)) g, PCIE_TRN_XMIT_X7 p,
                                  Clock fastClock, Reset fastReset,
                                  Clock slowClock, Reset slowReset)(Empty);

      mkConnectionWithClocks(p, g, fastClock, fastReset, slowClock, slowReset);
   endmodule
endinstance

instance ConnectableWithClocks#(Put#(TLPData#(16)), PCIE_TRN_RECV_X7);
   module mkConnectionWithClocks#(Put#(TLPData#(16)) p, PCIE_TRN_RECV_X7 g,
                                  Clock fastClock, Reset fastReset,
                                  Clock slowClock, Reset slowReset)(Empty);

      ////////////////////////////////////////////////////////////////////////////////
      /// Design Elements
      ////////////////////////////////////////////////////////////////////////////////
      FIFO#(TLPData#(8))                        inFifo              <- mkFIFO(clocked_by fastClock, reset_by fastReset);
      Gearbox#(1, 2, TLPData#(8))               fifoRxData          <- mk1toNGearbox(fastClock, fastReset, slowClock, slowReset);

      Reg#(Bool)                                rOddBeat            <- mkRegA(False, clocked_by fastClock, reset_by fastReset);
      Reg#(Bool)                                rSendInvalid        <- mkRegA(False, clocked_by fastClock, reset_by fastReset);

      ////////////////////////////////////////////////////////////////////////////////
      /// Rules
      ////////////////////////////////////////////////////////////////////////////////
      (* no_implicit_conditions, fire_when_enabled *)
      rule every;
         g.non_posted_ok(True);
	 g.non_posted_req(True);
      endrule

      rule accept_data;
         let data <- g.recv;
         inFifo.enq(tpl_3(data));
      endrule

      rule process_incoming_packets(!rSendInvalid);
         let data = inFifo.first; inFifo.deq;
         rOddBeat     <= !rOddBeat;
         rSendInvalid <= !rOddBeat && data.eof;
         Vector#(1, TLPData#(8)) v = defaultValue;
         v[0] = data;
         fifoRxData.enq(v);
      endrule

      rule send_invalid_packets(rSendInvalid);
         rOddBeat     <= !rOddBeat;
         rSendInvalid <= False;
         Vector#(1, TLPData#(8)) v = defaultValue;
         v[0].eof = True;
         v[0].be  = 0;
         fifoRxData.enq(v);
      endrule

      rule send_data;
         function TLPData#(16) combine(Vector#(2, TLPData#(8)) in);
            return TLPData {
                            sof:   in[0].sof,
                            eof:   in[1].eof,
                            hit:   in[0].hit,
                            be:    { in[0].be,   in[1].be },
                            data:  { in[0].data, in[1].data }
                            };
         endfunction

         fifoRxData.deq;
         p.put(combine(fifoRxData.first));
      endrule

   endmodule
endinstance

instance ConnectableWithClocks#(PCIE_TRN_RECV_X7, Put#(TLPData#(16)));
   module mkConnectionWithClocks#(PCIE_TRN_RECV_X7 g, Put#(TLPData#(16)) p,
                                  Clock fastClock, Reset fastReset,
                                  Clock slowClock, Reset slowReset)(Empty);
      mkConnectionWithClocks(p, g, fastClock, fastReset, slowClock, slowReset);
   endmodule
endinstance

// interface tie-offs


instance TieOff#(PCIE_CFG_X7);
   module mkTieOff#(PCIE_CFG_X7 ifc)(Empty);
      rule tie_off_inputs;
	 ifc.di(0);
	 ifc.dwaddr(0);
	 ifc.byte_en(0);
	 ifc.wr_en(0);
	 ifc.rd_en(0);
	 ifc.wr_readonly(0);
	 ifc.trn_pending(0);
	 ifc.dsn({ 32'h0000_0001, {{ 8'h1 } , 24'h000A35 }});
	 ifc.pm_halt_aspm_l0s(0);
	 ifc.pm_halt_aspm_l1(0);
	 ifc.pm_force_state(0);
	 ifc.pm_force_state_en(0);
	 ifc.turnoff_ok(0);
	 ifc.pm_wake(0);
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_INT_X7);
   module mkTieOff#(PCIE_INT_X7 ifc)(Empty);
      rule tie_off_inputs;
	 ifc.req(0);
	 ifc.assrt(0);
	 ifc.di(0);
	 ifc.pciecap_msgnum(0);
	 ifc.stat(0);
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_ERR_X7);
   module mkTieOff#(PCIE_ERR_X7 ifc)(Empty);
      rule tie_off_inputs;
	 ifc.ecrc(0);
	 ifc.ur(0);
	 ifc.cpl_timeout(0);
	 ifc.cpl_unexpect(0);
	 ifc.cpl_abort(0);
	 ifc.posted(0);
	 ifc.cor(0);
	 ifc.atomic_egress_blocked(0);
	 ifc.internal_cor(0);
	 ifc.internal_uncor(0);
	 ifc.malformed(0);
	 ifc.mc_blocked(0);
	 ifc.poisoned(0);
	 ifc.no_recovery(0);
	 ifc.tlp_cpl_header(0);
	 ifc.locked(0);
	 ifc.aer_headerlog(0);
	 ifc.aer_interrupt_msgnum(0);
	 ifc.acs(0);
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_PL_X7);
   module mkTieOff#(PCIE_PL_X7 ifc)(Empty);
      rule tie_off_inputs;
	 ifc.directed_link_auton(0);
	 ifc.directed_link_change(0);
	 ifc.directed_link_speed(0);
	 ifc.directed_link_width(0);
	 ifc.upstream_prefer_deemph(1);
      endrule
   endmodule
endinstance

endpackage: XbsvXilinx7Pcie

