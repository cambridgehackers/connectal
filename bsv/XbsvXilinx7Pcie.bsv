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

import XbsvXilinxCells   ::*;
import XilinxCells       ::*;
import PCIE              ::*;
import PCIEWRAPPER       ::*;

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
   interface PciewrapPci_exp#(lanes) pcie;
   interface PCIE_TRN_X7      trn;
   interface PCIE_AXI_TX_X7   axi_tx;
   interface PCIE_AXI_RX_X7   axi_rx;
   interface PCIE_PL_X7       pl;
   interface PCIE_CFG_X7      cfg;
   interface PCIE_INT_X7      cfg_interrupt;
   interface PCIE_ERR_X7      cfg_err;
   interface Clock            txoutclk;
   method    Action           locked(Bit#(1) v);
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
module vMkXilinx7PCIExpress#(PCIEParams params, Clock clk_125mhz, Clock clk_250mhz, Clock clkout2)(PCIE_X7#(lanes))
   provisos( Add#(1, z, lanes));
   // PCIe wrapper takes active low reset
   let sys_reset_n <- exposeCurrentReset;
   
   default_clock clk(sys_clk); // 100 MHz refclk
   default_reset rstn(sys_reset_n) = sys_reset_n;
   input_clock clk_125mhz(clk_125mhz_) = clk_125mhz;
   input_clock clk_250mhz(clk_250mhz_) = clk_250mhz;
   input_clock clkout2(clkout2) = clkout2;
   method locked(locked) enable((*inhigh*)en_locked);
   
   interface PciewrapPci_exp pcie;
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
   output_clock txoutclk(txoutclk);
      
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
	     pcie_txp, pcie_txn, pcie_rxp, pcie_rxn, locked
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
	     pcie_txp, pcie_txn, pcie_rxp, pcie_rxn, locked
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
   interface PciewrapPci_exp#(lanes)   pcie;
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
typeclass MkXilinx7PCIE#(numeric type lanes);
   module mkXilinx7PCIE(PCIEParams params, Clock clk_125mhz, Clock clk_250mhz, Clock clkout2, PCIE_X7#(lanes) ifc);
endtypeclass

instance MkXilinx7PCIE#(8);
   module mkXilinx7PCIE(PCIEParams params, Clock clk_125mhz, Clock clk_250mhz, Clock clkout2, PCIE_X7#(8) ifc);
      let _ifc <- vMkXilinx7PCIExpress(params, clk_125mhz, clk_250mhz, clkout2);
      return _ifc;
   endmodule
endinstance

instance MkXilinx7PCIE#(4);
   module mkXilinx7PCIE(PCIEParams params, Clock clk_125mhz, Clock clk_250mhz, Clock clkout2, PCIE_X7#(4) ifc);
      let _ifc <- vMkXilinx7PCIExpress(params, clk_125mhz, clk_250mhz, clkout2);
      return _ifc;
   endmodule
endinstance

instance MkXilinx7PCIE#(1);
   module mkXilinx7PCIE(PCIEParams params, Clock clk_125mhz, Clock clk_250mhz, Clock clkout2, PCIE_X7#(1) ifc);
      let _ifc <- vMkXilinx7PCIExpress(params, clk_125mhz, clk_250mhz, clkout2);
      return _ifc;
   endmodule
endinstance

module mkPCIExpressEndpointX7#(PCIEParams params)(PCIExpressX7#(lanes))
   provisos(Add#(1, z, lanes), MkXilinx7PCIE#(lanes));
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   B2C1 b2c <- mkB2C1();
   ClockGenerator7AdvParams clockParams = defaultValue;
   clockParams.bandwidth          = "OPTIMIZED";
   clockParams.compensation       = "INTERNAL"; //ZHOLD
   clockParams.clkfbout_mult_f    = 10.000;
   clockParams.clkfbout_phase     = 0.0;
   clockParams.clkin1_period      = 10.000;
   clockParams.clkout0_divide_f   = 8.000;
   clockParams.clkout0_duty_cycle = 0.5;
   clockParams.clkout0_phase      = 0.0000;
   clockParams.clkout1_divide     = 4;
   clockParams.clkout1_duty_cycle = 0.5;
   clockParams.clkout1_phase      = 0.0000;
   clockParams.clkout2_divide     = 4;
   clockParams.clkout2_duty_cycle = 0.5;
   clockParams.clkout2_phase      = 0.0000;
   clockParams.clkout3_divide     = 4;
   clockParams.clkout3_duty_cycle = 0.5;
   clockParams.clkout3_phase      = 0.0000;
   clockParams.clkout4_divide     = 20;
   clockParams.clkout4_duty_cycle = 0.5;
   clockParams.clkout4_phase      = 0.0000;
   clockParams.divclk_divide      = 1;
   clockParams.ref_jitter1        = 0.010;

   clockParams.clkin_buffer = False;
   clockParams.clkout0_buffer = True;
   clockParams.clkout2_buffer = True;
   XClockGenerator7 clockGen <- mkClockGenerator7Adv(clockParams, clocked_by b2c.c); //mmcm_i ( .RST(1'b0)
   C2B c2b_fb <- mkC2B(clockGen.clkfbout, clocked_by clockGen.clkfbout);
   rule txoutrule5;
      clockGen.clkfbin(c2b_fb.o());
   endrule
/*
    BUFGCTRL pclk_i1 ( .CE0 (1'd1), .CE1 (1'd1),
        .I0 (clockGen.clkout0), .I1 (clockGen.clkout1), .IGNORE0 (1'd0), .IGNORE1 (1'd0),
        .S0 (~pclk_sel), .S1 ( pclk_sel), .O (PIPE_PCLK_IN));

   wire                PIPE_PCLK_IN;
   wire                PIPE_MMCM_LOCK_IN;
   wire                PIPE_TXOUTCLK_OUT;
   wire [7:0]          PIPE_PCLK_SEL_OUT;

reg         [PCIE_LANE-1:0] pclk_sel_reg1 = {PCIE_LANE{1'd0}};
reg         [PCIE_LANE-1:0] pclk_sel_reg2 = {PCIE_LANE{1'd0}};
    reg                pclk_sel = 1'd0;
    always @ (posedge PIPE_PCLK_IN)
    begin
        pclk_sel_reg1 <= PIPE_PCLK_SEL_OUT;
        pclk_sel_reg2 <= pclk_sel_reg1;
        if (&pclk_sel_reg2)
            pclk_sel <= 1'd1;
        else if (&(~pclk_sel_reg2))
            pclk_sel <= 1'd0;
        else
            pclk_sel <= pclk_sel;
    end
*/
////////JJJJJJJJJJJJJJJJJJJJ
   //PIPE_DCLK_IN clockGen.clkout0); //PIPE_USERCLK1_IN clockGen.clkout2); //.LOCKED(clockGen.locked),
   PCIE_X7#(lanes)                           pcie_ep             <- mkXilinx7PCIE(params, clockGen.clkout0, clockGen.clkout1, clockGen.clkout2);
   Clock txoutclk_buf <- mkClockBUFG(clocked_by pcie_ep.txoutclk);
   C2B c2b <- mkC2B(txoutclk_buf);
   rule txoutrule;
      b2c.inputclock(c2b.o());
   endrule
   rule lockedrule;
      pcie_ep.locked(pack(clockGen.locked));
   endrule

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

endpackage: XbsvXilinx7Pcie

