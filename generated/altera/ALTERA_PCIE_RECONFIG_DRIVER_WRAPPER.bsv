
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
   int_status
   -f
   l2_exit
   -f
   lane_act
   -f
   ltssmstate
   -f
   dlup
   -f
   rx_par_err
   -f
   tx_par_err
   -f
   cfg_par_err
   -f
   ko
   ../../out/de5/synthesis/altera_pcie_reconfig_driver.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface PciereconfigwrapCfg_par_err;
    method Action      drv(Bit#(1) v);
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
interface PciereconfigwrapInt_status;
    method Action      drv(Bit#(4) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapKo;
    method Action      cpl_spc_data_drv(Bit#(12) v);
    method Action      cpl_spc_header_drv(Bit#(8) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapL2_exit;
    method Action      drv(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapLane_act;
    method Action      drv(Bit#(4) v);
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
interface PciereconfigwrapRx_par_err;
    method Action      drv(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciereconfigwrapTx_par_err;
    method Action      drv(Bit#(2) v);
endinterface
(* always_ready, always_enabled *)
interface PcieReconfigWrap;
    interface PciereconfigwrapCfg_par_err     cfg_par_err;
    interface PciereconfigwrapCurrent     current;
    interface PciereconfigwrapDerr     derr;
    interface PciereconfigwrapDlup     dlup;
    interface PciereconfigwrapEv128ns     ev128ns;
    interface PciereconfigwrapEv1us     ev1us;
    interface PciereconfigwrapHotrst     hotrst;
    interface PciereconfigwrapInt_status     int_status;
    interface PciereconfigwrapKo     ko;
    interface PciereconfigwrapL2_exit     l2_exit;
    interface PciereconfigwrapLane_act     lane_act;
    interface PciereconfigwrapLtssmstate     ltssmstate;
    interface PciereconfigwrapReconfig_b     reconfig_b;
    interface PciereconfigwrapReconfig_mgmt     reconfig_mgmt;
    interface PciereconfigwrapRx_par_err     rx_par_err;
    interface PciereconfigwrapTx_par_err     tx_par_err;
endinterface
import "BVI" altera_pcie_reconfig_driver =
module mkPcieReconfigWrap#(Clock pld_clk, Clock reconfig_xcvr_clk, Reset pld_clk_reset, Reset reconfig_xcvr_clk_reset, Reset reconfig_xcvr_rst)(PcieReconfigWrap);
    default_clock clk();
    default_reset rst();
        input_clock pld_clk(pld_clk) = pld_clk;
        input_reset pld_clk_reset() = pld_clk_reset; /* from clock*/
        input_clock reconfig_xcvr_clk(reconfig_xcvr_clk) = reconfig_xcvr_clk;
        input_reset reconfig_xcvr_clk_reset() = reconfig_xcvr_clk_reset; /* from clock*/
        input_reset reconfig_xcvr_rst(reconfig_xcvr_rst) = reconfig_xcvr_rst;
    interface PciereconfigwrapCfg_par_err     cfg_par_err;
        method drv(cfg_par_errdrv) enable((*inhigh*) EN_cfg_par_errdrv);
    endinterface
    interface PciereconfigwrapCurrent     current;
        method speed(currentspeed) enable((*inhigh*) EN_currentspeed);
    endinterface
    interface PciereconfigwrapDerr     derr;
        method cor_ext_rcv_drv(derrcor_ext_rcv_drv) enable((*inhigh*) EN_derrcor_ext_rcv_drv);
        method cor_ext_rpl_drv(derrcor_ext_rpl_drv) enable((*inhigh*) EN_derrcor_ext_rpl_drv);
        method rpl_drv(derrrpl_drv) enable((*inhigh*) EN_derrrpl_drv);
    endinterface
    interface PciereconfigwrapDlup     dlup;
        method drv(dlupdrv) enable((*inhigh*) EN_dlupdrv);
        method exit_drv(dlupexit_drv) enable((*inhigh*) EN_dlupexit_drv);
    endinterface
    interface PciereconfigwrapEv128ns     ev128ns;
        method drv(ev128nsdrv) enable((*inhigh*) EN_ev128nsdrv);
    endinterface
    interface PciereconfigwrapEv1us     ev1us;
        method drv(ev1usdrv) enable((*inhigh*) EN_ev1usdrv);
    endinterface
    interface PciereconfigwrapHotrst     hotrst;
        method exit_drv(hotrstexit_drv) enable((*inhigh*) EN_hotrstexit_drv);
    endinterface
    interface PciereconfigwrapInt_status     int_status;
        method drv(int_statusdrv) enable((*inhigh*) EN_int_statusdrv);
    endinterface
    interface PciereconfigwrapKo     ko;
        method cpl_spc_data_drv(kocpl_spc_data_drv) enable((*inhigh*) EN_kocpl_spc_data_drv);
        method cpl_spc_header_drv(kocpl_spc_header_drv) enable((*inhigh*) EN_kocpl_spc_header_drv);
    endinterface
    interface PciereconfigwrapL2_exit     l2_exit;
        method drv(l2_exitdrv) enable((*inhigh*) EN_l2_exitdrv);
    endinterface
    interface PciereconfigwrapLane_act     lane_act;
        method drv(lane_actdrv) enable((*inhigh*) EN_lane_actdrv);
    endinterface
    interface PciereconfigwrapLtssmstate     ltssmstate;
        method drv(ltssmstatedrv) enable((*inhigh*) EN_ltssmstatedrv);
    endinterface
    interface PciereconfigwrapReconfig_b     reconfig_b;
        method usy(reconfig_busy) enable((*inhigh*) EN_reconfig_busy);
    endinterface
    interface PciereconfigwrapReconfig_mgmt     reconfig_mgmt;
        method reconfig_mgmtaddress address();
        method reconfig_mgmtread read();
        method readdata(reconfig_mgmtreaddata) enable((*inhigh*) EN_reconfig_mgmtreaddata);
        method waitrequest(reconfig_mgmtwaitrequest) enable((*inhigh*) EN_reconfig_mgmtwaitrequest);
        method reconfig_mgmtwrite write();
        method reconfig_mgmtwritedata writedata();
    endinterface
    interface PciereconfigwrapRx_par_err     rx_par_err;
        method drv(rx_par_errdrv) enable((*inhigh*) EN_rx_par_errdrv);
    endinterface
    interface PciereconfigwrapTx_par_err     tx_par_err;
        method drv(tx_par_errdrv) enable((*inhigh*) EN_tx_par_errdrv);
    endinterface
    schedule (cfg_par_err.drv, current.speed, derr.cor_ext_rcv_drv, derr.cor_ext_rpl_drv, derr.rpl_drv, dlup.drv, dlup.exit_drv, ev128ns.drv, ev1us.drv, hotrst.exit_drv, int_status.drv, ko.cpl_spc_data_drv, ko.cpl_spc_header_drv, l2_exit.drv, lane_act.drv, ltssmstate.drv, reconfig_b.usy, reconfig_mgmt.address, reconfig_mgmt.read, reconfig_mgmt.readdata, reconfig_mgmt.waitrequest, reconfig_mgmt.write, reconfig_mgmt.writedata, rx_par_err.drv, tx_par_err.drv) CF (cfg_par_err.drv, current.speed, derr.cor_ext_rcv_drv, derr.cor_ext_rpl_drv, derr.rpl_drv, dlup.drv, dlup.exit_drv, ev128ns.drv, ev1us.drv, hotrst.exit_drv, int_status.drv, ko.cpl_spc_data_drv, ko.cpl_spc_header_drv, l2_exit.drv, lane_act.drv, ltssmstate.drv, reconfig_b.usy, reconfig_mgmt.address, reconfig_mgmt.read, reconfig_mgmt.readdata, reconfig_mgmt.waitrequest, reconfig_mgmt.write, reconfig_mgmt.writedata, rx_par_err.drv, tx_par_err.drv);
endmodule
