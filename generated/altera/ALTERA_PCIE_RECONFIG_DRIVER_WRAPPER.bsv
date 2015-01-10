
/*
   ./importbvi.py
   -o
   ALTERA_PCIE_RECONFIG_DRIVER_WRAPPER.bsv
   -I
   PcieReconfigWrap
   -P
   PcieReconfigWrap
   -c
   reconfig_xcvr_clk
   -c
   pld_clk
   -r
   reconfig_xcvr_rst
   -f
   reconfig_mgmt
   -f
   reconfig_b
   -f
   current
   -f
   derr
   -f
   dlup
   -f
   ev128ns
   -f
   ev1us
   -f
   hotrst
   -f
   int_s
   -f
   l2
   -f
   lane
   -f
   ltssmstate
   -f
   dlup
   -f
   rx
   -f
   tx
   -f
   tx
   -f
   rx
   -f
   cfg
   -f
   ko
   ../../out/de5/synthesis/altera_pcie_reconfig_driver_wrapper.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface PciereconfigwrapCfg;
    method Action      par_err_drv(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapCurrent;
    method Action      speed(Bit#(2) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapDerr;
    method Action      cor_ext_rcv_drv(Bit#(1) v);
    method Action      cor_ext_rpl_drv(Bit#(1) v);
    method Action      rpl_drv(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapDlup;
    method Action      drv(Bit#(1) v);
    method Action      exit_drv(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapEv128ns;
    method Action      drv(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapEv1us;
    method Action      drv(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapHotrst;
    method Action      exit_drv(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapInt_s;
    method Action      tatus_drv(Bit#(4) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapKo;
    method Action      cpl_spc_data_drv(Bit#(12) v);
    method Action      cpl_spc_header_drv(Bit#(8) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapL2;
    method Action      exit_drv(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapLane;
    method Action      act_drv(Bit#(4) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapLtssmstate;
    method Action      drv(Bit#(5) v);
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface PciereconfigwrapReconfig_b;
    method Action      usy(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapReconfig_mgmt;
    method Bit#(7)     address();
    method Bit#(1)     read();
    method Action      readdata(Bit#(32) v);
    method Action      waitrequest(Bit#(1) v);
    method Bit#(1)     write();
    method Bit#(32)     writedata();
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapRx;
    method Action      par_err_drv(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapTx;
    method Action      par_err_drv(Bit#(2) v);
endinterface
(* always_ready, always_enabled *)
interface PcieReconfigWrap;
    interface PciereconfigwrapCfg     cfg;
    interface PciereconfigwrapCurrent     current;
    interface PciereconfigwrapDerr     derr;
    interface PciereconfigwrapDlup     dlup;
    interface PciereconfigwrapEv128ns     ev128ns;
    interface PciereconfigwrapEv1us     ev1us;
    interface PciereconfigwrapHotrst     hotrst;
    interface PciereconfigwrapInt_s     int_s;
    interface PciereconfigwrapKo     ko;
    interface PciereconfigwrapL2     l2;
    interface PciereconfigwrapLane     lane;
    interface PciereconfigwrapLtssmstate     ltssmstate;
    interface PciereconfigwrapReconfig_b     reconfig_b;
    interface PciereconfigwrapReconfig_mgmt     reconfig_mgmt;
    interface PciereconfigwrapRx     rx;
    interface PciereconfigwrapTx     tx;
endinterface
import "BVI" altera_pcie_reconfig_driver_wrapper =
module mkPcieReconfigWrap#(Clock pld_clk, Clock reconfig_xcvr_clk, Reset pld_clk_reset, Reset reconfig_xcvr_clk_reset, Reset reconfig_xcvr_rst)(PcieReconfigWrap);
    default_clock clk();
    default_reset rst();
        input_clock pld_clk(pld_clk) = pld_clk;
        input_reset pld_clk_reset() = pld_clk_reset; /* from clock*/
        input_clock reconfig_xcvr_clk(reconfig_xcvr_clk) = reconfig_xcvr_clk;
        input_reset reconfig_xcvr_clk_reset() = reconfig_xcvr_clk_reset; /* from clock*/
        input_reset reconfig_xcvr_rst(reconfig_xcvr_rst) = reconfig_xcvr_rst;
    interface PciereconfigwrapCfg     cfg;
        method par_err_drv(cfg_par_err_drv) clocked_by(pld_clk) enable((*inhigh*) EN_cfg_par_err_drv);
    endinterface
    interface PciereconfigwrapCurrent     current;
        method speed(currentspeed) clocked_by(pld_clk) enable((*inhigh*) EN_currentspeed);
    endinterface
    interface PciereconfigwrapDerr     derr;
        method cor_ext_rcv_drv(derr_cor_ext_rcv_drv) clocked_by(pld_clk) enable((*inhigh*) EN_derr_cor_ext_rcv_drv);
        method cor_ext_rpl_drv(derr_cor_ext_rpl_drv) clocked_by(pld_clk) enable((*inhigh*) EN_derr_cor_ext_rpl_drv);
        method rpl_drv(derr_rpl_drv) clocked_by(pld_clk) enable((*inhigh*) EN_derr_rpl_drv);
    endinterface
    interface PciereconfigwrapDlup     dlup;
        method drv(dlup_drv) clocked_by(pld_clk) enable((*inhigh*) EN_dlup_drv);
        method exit_drv(dlup_exit_drv) clocked_by(pld_clk) enable((*inhigh*) EN_dlup_exit_drv);
    endinterface
    interface PciereconfigwrapEv128ns     ev128ns;
        method drv(ev128ns_drv) clocked_by(pld_clk) enable((*inhigh*) EN_ev128ns_drv);
    endinterface
    interface PciereconfigwrapEv1us     ev1us;
        method drv(ev1us_drv) clocked_by(pld_clk) enable((*inhigh*) EN_ev1us_drv);
    endinterface
    interface PciereconfigwrapHotrst     hotrst;
        method exit_drv(hotrst_exit_drv) clocked_by(pld_clk) enable((*inhigh*) EN_hotrst_exit_drv);
    endinterface
    interface PciereconfigwrapInt_s     int_s;
        method tatus_drv(int_status_drv) clocked_by(pld_clk) enable((*inhigh*) EN_int_status_drv);
    endinterface
    interface PciereconfigwrapKo     ko;
        method cpl_spc_data_drv(ko_cpl_spc_data_drv) clocked_by(pld_clk) enable((*inhigh*) EN_ko_cpl_spc_data_drv);
        method cpl_spc_header_drv(ko_cpl_spc_header_drv) clocked_by(pld_clk) enable((*inhigh*) EN_ko_cpl_spc_header_drv);
    endinterface
    interface PciereconfigwrapL2     l2;
        method exit_drv(l2_exit_drv) clocked_by(pld_clk) enable((*inhigh*) EN_l2_exit_drv);
    endinterface
    interface PciereconfigwrapLane     lane;
        method act_drv(lane_act_drv) clocked_by(pld_clk) enable((*inhigh*) EN_lane_act_drv);
    endinterface
    interface PciereconfigwrapLtssmstate     ltssmstate;
        method drv(ltssmstate_drv) clocked_by(pld_clk) enable((*inhigh*) EN_ltssmstate_drv);
    endinterface
    interface PciereconfigwrapReconfig_b     reconfig_b;
        method usy(reconfig_busy) enable((*inhigh*) EN_reconfig_busy);
    endinterface
    interface PciereconfigwrapReconfig_mgmt     reconfig_mgmt;
        method reconfig_mgmt_address address();
        method reconfig_mgmt_read read();
        method readdata(reconfig_mgmt_readdata) enable((*inhigh*) EN_reconfig_mgmt_readdata);
        method waitrequest(reconfig_mgmt_waitrequest) enable((*inhigh*) EN_reconfig_mgmt_waitrequest);
        method reconfig_mgmt_write write();
        method reconfig_mgmt_writedata writedata();
    endinterface
    interface PciereconfigwrapRx     rx;
        method par_err_drv(rx_par_err_drv) clocked_by(pld_clk) enable((*inhigh*) EN_rx_par_err_drv);
    endinterface
    interface PciereconfigwrapTx     tx;
        method par_err_drv(tx_par_err_drv) clocked_by(pld_clk) enable((*inhigh*) EN_tx_par_err_drv);
    endinterface
    schedule (cfg.par_err_drv, current.speed, derr.cor_ext_rcv_drv, derr.cor_ext_rpl_drv, derr.rpl_drv, dlup.drv, dlup.exit_drv, ev128ns.drv, ev1us.drv, hotrst.exit_drv, int_s.tatus_drv, ko.cpl_spc_data_drv, ko.cpl_spc_header_drv, l2.exit_drv, lane.act_drv, ltssmstate.drv, reconfig_b.usy, reconfig_mgmt.address, reconfig_mgmt.read, reconfig_mgmt.readdata, reconfig_mgmt.waitrequest, reconfig_mgmt.write, reconfig_mgmt.writedata, rx.par_err_drv, tx.par_err_drv) CF (cfg.par_err_drv, current.speed, derr.cor_ext_rcv_drv, derr.cor_ext_rpl_drv, derr.rpl_drv, dlup.drv, dlup.exit_drv, ev128ns.drv, ev1us.drv, hotrst.exit_drv, int_s.tatus_drv, ko.cpl_spc_data_drv, ko.cpl_spc_header_drv, l2.exit_drv, lane.act_drv, ltssmstate.drv, reconfig_b.usy, reconfig_mgmt.address, reconfig_mgmt.read, reconfig_mgmt.readdata, reconfig_mgmt.waitrequest, reconfig_mgmt.write, reconfig_mgmt.writedata, rx.par_err_drv, tx.par_err_drv);
endmodule
