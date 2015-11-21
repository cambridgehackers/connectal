
/*
   ../scripts/importbvi.py
   -I
   AxiDdr3
   -o
   AxiDdr3Wrapper.bsv
   -P
   AxiDdr3
   -f
   ddr3
   -c ui_clk
   -r ui_clk_sync_rst
   -c sys_clk_i
   -r sys_rst
   /home/jamey/connectal/out/vc707/axiddr3/axiddr3_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;

(* always_ready, always_enabled *)
interface AxiDdr3App;
    method Bit#(1)     ref_ack();
    method Action      ref_req(Bit#(1) v);
    method Bit#(1)     sr_active();
    method Action      sr_req(Bit#(1) v);
    method Bit#(1)     zq_ack();
    method Action      zq_req(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface AxiDdr3Ddr3;
    method Bit#(14)     addr();
    method Bit#(3)     ba();
    method Bit#(1)     cas_n();
    method Bit#(1)     ck_n();
    method Bit#(1)     ck_p();
    method Bit#(1)     cke();
    method Bit#(1)     cs_n();
    method Bit#(8)     dm();
    interface Inout#(Bit#(64))     dq;
    interface Inout#(Bit#(8))     dqs_n;
    interface Inout#(Bit#(8))     dqs_p;
    method Bit#(1)     odt();
    method Bit#(1)     ras_n();
    method Bit#(1)     reset_n();
    method Bit#(1)     we_n();
endinterface
(* always_ready, always_enabled *)
interface AxiDdr3Init;
    method Bit#(1)     calib_complete();
endinterface
(* always_ready, always_enabled *)
interface AxiDdr3Mmcm;
    method Bit#(1)     locked();
endinterface
(* always_ready, always_enabled *)
interface AxiDdr3S_axi;
    method Action      araddr(Bit#(30) v);
    method Action      arburst(Bit#(2) v);
    method Action      arcache(Bit#(4) v);
    method Action      arid(Bit#(6) v);
    method Action      arlen(Bit#(8) v);
    method Action      arlock(Bit#(1) v);
    method Action      arprot(Bit#(3) v);
    method Action      arqos(Bit#(4) v);
    method Bit#(1)     arready();
    method Action      arsize(Bit#(3) v);
    method Action      arvalid(Bit#(1) v);
    method Action      awaddr(Bit#(30) v);
    method Action      awburst(Bit#(2) v);
    method Action      awcache(Bit#(4) v);
    method Action      awid(Bit#(6) v);
    method Action      awlen(Bit#(8) v);
    method Action      awlock(Bit#(1) v);
    method Action      awprot(Bit#(3) v);
    method Action      awqos(Bit#(4) v);
    method Bit#(1)     awready();
    method Action      awsize(Bit#(3) v);
    method Action      awvalid(Bit#(1) v);
    method Bit#(6)     bid();
    method Action      bready(Bit#(1) v);
    method Bit#(2)     bresp();
    method Bit#(1)     bvalid();
    method Bit#(512)     rdata();
    method Bit#(6)     rid();
    method Bit#(1)     rlast();
    method Action      rready(Bit#(1) v);
    method Bit#(2)     rresp();
    method Bit#(1)     rvalid();
    method Action      wdata(Bit#(512) v);
    method Action      wlast(Bit#(1) v);
    method Bit#(1)     wready();
    method Action      wstrb(Bit#(64) v);
    method Action      wvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface AxiDdr3;
    interface AxiDdr3App     app;
    interface AxiDdr3Ddr3     ddr3;
    interface AxiDdr3Init     init;
    interface AxiDdr3Mmcm     mmcm;
    interface AxiDdr3S_axi   s_axi;
    interface Clock ui_clk;
    interface Reset ui_clk_sync_rst;
endinterface
import "BVI" axiddr3 =
module mkAxiDdr3#(Clock sys_clk, Reset sys_rst, Reset aresetn)(AxiDdr3);
   default_clock  sys_clk_i(sys_clk_i) = sys_clk;
   default_reset  sys_rst(sys_rst) = sys_rst;
   output_clock  ui_clk(ui_clk);
   output_reset  ui_clk_sync_rst(ui_clk_sync_rst);
   input_reset aresetn(aresetn) = aresetn;
    interface AxiDdr3App     app;
        method app_ref_ack ref_ack() clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method ref_req(app_ref_req) enable((*inhigh*) EN_app_ref_req) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method app_sr_active sr_active() clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method sr_req(app_sr_req) enable((*inhigh*) EN_app_sr_req) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method app_zq_ack zq_ack() clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method zq_req(app_zq_req) enable((*inhigh*) EN_app_zq_req) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
    endinterface
    interface AxiDdr3Ddr3     ddr3;
        method ddr3_addr addr() clocked_by (no_clock) reset_by (no_reset);
        method ddr3_ba ba() clocked_by (no_clock) reset_by (no_reset);
        method ddr3_cas_n cas_n() clocked_by (no_clock) reset_by (no_reset);
        method ddr3_ck_n ck_n() clocked_by (no_clock) reset_by (no_reset);
        method ddr3_ck_p ck_p() clocked_by (no_clock) reset_by (no_reset);
        method ddr3_cke cke() clocked_by (no_clock) reset_by (no_reset);
        method ddr3_cs_n cs_n() clocked_by (no_clock) reset_by (no_reset);
        method ddr3_dm dm() clocked_by (no_clock) reset_by (no_reset);
        ifc_inout dq(ddr3_dq) clocked_by (no_clock) reset_by (no_reset);
        ifc_inout dqs_n(ddr3_dqs_n) clocked_by (no_clock) reset_by (no_reset);
        ifc_inout dqs_p(ddr3_dqs_p) clocked_by (no_clock) reset_by (no_reset);
        method ddr3_odt odt() clocked_by (no_clock) reset_by (no_reset);
        method ddr3_ras_n ras_n() clocked_by (no_clock) reset_by (no_reset);
        method ddr3_reset_n reset_n() clocked_by (no_clock) reset_by (no_reset);
        method ddr3_we_n we_n() clocked_by (no_clock) reset_by (no_reset);
    endinterface
    interface AxiDdr3Init     init;
        method init_calib_complete calib_complete() clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
    endinterface
    interface AxiDdr3Mmcm     mmcm;
        method mmcm_locked locked() clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
    endinterface
    interface AxiDdr3S_axi     s_axi;
        method araddr(s_axi_araddr) enable((*inhigh*) EN_s_axi_araddr) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method arburst(s_axi_arburst) enable((*inhigh*) EN_s_axi_arburst) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method arcache(s_axi_arcache) enable((*inhigh*) EN_s_axi_arcache) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method arid(s_axi_arid) enable((*inhigh*) EN_s_axi_arid) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method arlen(s_axi_arlen) enable((*inhigh*) EN_s_axi_arlen) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method arlock(s_axi_arlock) enable((*inhigh*) EN_s_axi_arlock) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method arprot(s_axi_arprot) enable((*inhigh*) EN_s_axi_arprot) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method arqos(s_axi_arqos) enable((*inhigh*) EN_s_axi_arqos) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method s_axi_arready arready() clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method arsize(s_axi_arsize) enable((*inhigh*) EN_s_axi_arsize) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method arvalid(s_axi_arvalid) enable((*inhigh*) EN_s_axi_arvalid) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method awaddr(s_axi_awaddr) enable((*inhigh*) EN_s_axi_awaddr) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method awburst(s_axi_awburst) enable((*inhigh*) EN_s_axi_awburst) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method awcache(s_axi_awcache) enable((*inhigh*) EN_s_axi_awcache) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method awid(s_axi_awid) enable((*inhigh*) EN_s_axi_awid) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method awlen(s_axi_awlen) enable((*inhigh*) EN_s_axi_awlen) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method awlock(s_axi_awlock) enable((*inhigh*) EN_s_axi_awlock) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method awprot(s_axi_awprot) enable((*inhigh*) EN_s_axi_awprot) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method awqos(s_axi_awqos) enable((*inhigh*) EN_s_axi_awqos) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method s_axi_awready awready() clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method awsize(s_axi_awsize) enable((*inhigh*) EN_s_axi_awsize) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method awvalid(s_axi_awvalid) enable((*inhigh*) EN_s_axi_awvalid) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method s_axi_bid bid() clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method bready(s_axi_bready) enable((*inhigh*) EN_s_axi_bready) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method s_axi_bresp bresp() clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method s_axi_bvalid bvalid() clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method s_axi_rdata rdata() clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method s_axi_rid rid() clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method s_axi_rlast rlast() clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method rready(s_axi_rready) enable((*inhigh*) EN_s_axi_rready) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method s_axi_rresp rresp() clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method s_axi_rvalid rvalid() clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method wdata(s_axi_wdata) enable((*inhigh*) EN_s_axi_wdata) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method wlast(s_axi_wlast) enable((*inhigh*) EN_s_axi_wlast) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method s_axi_wready wready() clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method wstrb(s_axi_wstrb) enable((*inhigh*) EN_s_axi_wstrb) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
        method wvalid(s_axi_wvalid) enable((*inhigh*) EN_s_axi_wvalid) clocked_by (ui_clk) reset_by (ui_clk_sync_rst);
    endinterface
    schedule (app.ref_ack, app.ref_req, app.sr_active, app.sr_req, app.zq_ack, app.zq_req, ddr3.addr, ddr3.ba, ddr3.cas_n, ddr3.ck_n, ddr3.ck_p, ddr3.cke, ddr3.cs_n, ddr3.dm, ddr3.odt, ddr3.ras_n, ddr3.reset_n, ddr3.we_n, init.calib_complete, mmcm.locked, s_axi.araddr, s_axi.arburst, s_axi.arcache, s_axi.arid, s_axi.arlen, s_axi.arlock, s_axi.arprot, s_axi.arqos, s_axi.arready, s_axi.arsize, s_axi.arvalid, s_axi.awaddr, s_axi.awburst, s_axi.awcache, s_axi.awid, s_axi.awlen, s_axi.awlock, s_axi.awprot, s_axi.awqos, s_axi.awready, s_axi.awsize, s_axi.awvalid, s_axi.bid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rid, s_axi.rlast, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wlast, s_axi.wready, s_axi.wstrb, s_axi.wvalid) CF (app.ref_ack, app.ref_req, app.sr_active, app.sr_req, app.zq_ack, app.zq_req, ddr3.addr, ddr3.ba, ddr3.cas_n, ddr3.ck_n, ddr3.ck_p, ddr3.cke, ddr3.cs_n, ddr3.dm, ddr3.odt, ddr3.ras_n, ddr3.reset_n, ddr3.we_n, init.calib_complete, mmcm.locked, s_axi.araddr, s_axi.arburst, s_axi.arcache, s_axi.arid, s_axi.arlen, s_axi.arlock, s_axi.arprot, s_axi.arqos, s_axi.arready, s_axi.arsize, s_axi.arvalid, s_axi.awaddr, s_axi.awburst, s_axi.awcache, s_axi.awid, s_axi.awlen, s_axi.awlock, s_axi.awprot, s_axi.awqos, s_axi.awready, s_axi.awsize, s_axi.awvalid, s_axi.bid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rid, s_axi.rlast, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wlast, s_axi.wready, s_axi.wstrb, s_axi.wvalid);
endmodule
