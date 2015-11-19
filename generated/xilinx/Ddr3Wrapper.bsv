
/*
   ../scripts/importbvi.py
   -I
   Dram
   -o
   Ddr3Wrapper.bsv
   -P
   ddr
   /home/jamey/connectal/out/vc707/ddr3/ddr3_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;

(* always_ready, always_enabled *)
interface DdrApp;
    method Action      addr(Bit#(28) v);
    method Action      cmd(Bit#(3) v);
    method Action      en(Bit#(1) v);
    method Bit#(512)     rd_data();
    method Bit#(1)     rd_data_end();
    method Bit#(1)     rd_data_valid();
    method Bit#(1)     rdy();
    method Bit#(1)     ref_ack();
    method Action      ref_req(Bit#(1) v);
    method Bit#(1)     sr_active();
    method Action      sr_req(Bit#(1) v);
    method Action      wdf_data(Bit#(512) v);
    method Action      wdf_end(Bit#(1) v);
    method Action      wdf_mask(Bit#(64) v);
    method Bit#(1)     wdf_rdy();
    method Action      wdf_wren(Bit#(1) v);
    method Bit#(1)     zq_ack();
    method Action      zq_req(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface DdrClk;
    method Action      ref_i(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface DdrInit;
    method Bit#(1)     calib_complete();
endinterface
(* always_ready, always_enabled *)
interface DdrSys;
    method Action      clk_i(Bit#(1) v);
    method Action      rst(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface DdrUi;
    method Bit#(1)     clk();
    method Bit#(1)     clk_sync_rst();
endinterface
(* always_ready, always_enabled *)
interface Dram;
    interface DdrApp     app;
    interface DdrClk     clk;
    interface DdrDdr     ddr3;
    interface DdrInit     init;
    interface DdrSys     sys;
    interface DdrUi     ui;
endinterface
import "BVI" ddr3(ddr3_dq, =
module mkDram(Dram);
    default_clock clk();
    default_reset rst();
    interface DdrApp     app;
        method addr(app_addr) enable((*inhigh*) EN_app_addr);
        method cmd(app_cmd) enable((*inhigh*) EN_app_cmd);
        method en(app_en) enable((*inhigh*) EN_app_en);
        method app_rd_data rd_data();
        method app_rd_data_end rd_data_end();
        method app_rd_data_valid rd_data_valid();
        method app_rdy rdy();
        method app_ref_ack ref_ack();
        method ref_req(app_ref_req) enable((*inhigh*) EN_app_ref_req);
        method app_sr_active sr_active();
        method sr_req(app_sr_req) enable((*inhigh*) EN_app_sr_req);
        method wdf_data(app_wdf_data) enable((*inhigh*) EN_app_wdf_data);
        method wdf_end(app_wdf_end) enable((*inhigh*) EN_app_wdf_end);
        method wdf_mask(app_wdf_mask) enable((*inhigh*) EN_app_wdf_mask);
        method app_wdf_rdy wdf_rdy();
        method wdf_wren(app_wdf_wren) enable((*inhigh*) EN_app_wdf_wren);
        method app_zq_ack zq_ack();
        method zq_req(app_zq_req) enable((*inhigh*) EN_app_zq_req);
    endinterface
    interface DdrClk     clk;
        method ref_i(clk_ref_i) enable((*inhigh*) EN_clk_ref_i);
    endinterface
    interface DdrDdr     ddr3;
    interface DdrInit     init;
        method init_calib_complete calib_complete();
    endinterface
    interface DdrSys     sys;
        method clk_i(sys_clk_i) enable((*inhigh*) EN_sys_clk_i);
        method rst(sys_rst) enable((*inhigh*) EN_sys_rst);
    endinterface
    interface DdrUi     ui;
        method ui_clk clk();
        method ui_clk_sync_rst clk_sync_rst();
    endinterface
    schedule (app.addr, app.cmd, app.en, app.rd_data, app.rd_data_end, app.rd_data_valid, app.rdy, app.ref_ack, app.ref_req, app.sr_active, app.sr_req, app.wdf_data, app.wdf_end, app.wdf_mask, app.wdf_rdy, app.wdf_wren, app.zq_ack, app.zq_req, clk.ref_i, init.calib_complete, sys.clk_i, sys.rst, ui.clk, ui.clk_sync_rst) CF (app.addr, app.cmd, app.en, app.rd_data, app.rd_data_end, app.rd_data_valid, app.rdy, app.ref_ack, app.ref_req, app.sr_active, app.sr_req, app.wdf_data, app.wdf_end, app.wdf_mask, app.wdf_rdy, app.wdf_wren, app.zq_ack, app.zq_req, clk.ref_i, init.calib_complete, sys.clk_i, sys.rst, ui.clk, ui.clk_sync_rst);
endmodule
