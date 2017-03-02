
/*
   ../scripts/importbvi.py
   -c
   maxihpm0_fpd_aclk
   -c
   maxihpm0_fpd_aclk
   -c
   maxihpm0_lpd_aclk
   -I
   PS8
   -P
   PS8
   -o
   ZYNQ_ULTRA.bsv
   ../../out/zcu102/zynq_ultra_ps_e_0/zynq_ultra_ps_e_0_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;

(* always_ready, always_enabled *)
interface Ps8Maxigp;
    method Bit#(40)     araddr();
    method Bit#(2)     arburst();
    method Bit#(4)     arcache();
    method Bit#(16)     arid();
    method Bit#(8)     arlen();
    method Bit#(1)     arlock();
    method Bit#(3)     arprot();
    method Bit#(4)     arqos();
    method Action      arready(Bit#(1) v);
    method Bit#(3)     arsize();
    method Bit#(16)     aruser();
    method Bit#(1)     arvalid();
    method Bit#(40)     awaddr();
    method Bit#(2)     awburst();
    method Bit#(4)     awcache();
    method Bit#(16)     awid();
    method Bit#(8)     awlen();
    method Bit#(1)     awlock();
    method Bit#(3)     awprot();
    method Bit#(4)     awqos();
    method Action      awready(Bit#(1) v);
    method Bit#(3)     awsize();
    method Bit#(16)     awuser();
    method Bit#(1)     awvalid();
    method Action      bid(Bit#(16) v);
    method Bit#(1)     bready();
    method Action      bresp(Bit#(2) v);
    method Action      bvalid(Bit#(1) v);
    method Action      rdata(Bit#(32) v);
    method Action      rid(Bit#(16) v);
    method Action      rlast(Bit#(1) v);
    method Bit#(1)     rready();
    method Action      rresp(Bit#(2) v);
    method Action      rvalid(Bit#(1) v);
    method Bit#(32)     wdata();
    method Bit#(1)     wlast();
    method Action      wready(Bit#(1) v);
    method Bit#(4)     wstrb();
    method Bit#(1)     wvalid();
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface Ps8Pl;
    method Bit#(1)     clk0();
    method Bit#(1)     clk1();
    method Action      ps_irq0(Bit#(1) v);
    method Bit#(1)     resetn0();
endinterface
(* always_ready, always_enabled *)
interface PS8;
    interface Ps8Maxigp     maxigp0;
    interface Ps8Maxigp     maxigp2;
    interface Ps8Pl     pl;
endinterface
import "BVI" zynq_ultra_ps_e_0 =
module mkPS8#(Clock maxihpm0_fpd_aclk, Clock maxihpm0_lpd_aclk)(PS8);
    default_clock no_clock;
    default_reset no_reset;
        input_clock maxihpm0_fpd_aclk(maxihpm0_fpd_aclk) = maxihpm0_fpd_aclk;
         /* from clock*/
        input_clock maxihpm0_lpd_aclk(maxihpm0_lpd_aclk) = maxihpm0_lpd_aclk;
         /* from clock*/
    interface Ps8Maxigp     maxigp0;
        method maxigp0_araddr araddr() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_arburst arburst() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_arcache arcache() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_arid arid() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_arlen arlen() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_arlock arlock() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_arprot arprot() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_arqos arqos() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method arready(maxigp0_arready) enable((*inhigh*) EN_maxigp0_arready) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_arsize arsize() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_aruser aruser() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_arvalid arvalid() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_awaddr awaddr() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_awburst awburst() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_awcache awcache() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_awid awid() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_awlen awlen() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_awlock awlock() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_awprot awprot() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_awqos awqos() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method awready(maxigp0_awready) enable((*inhigh*) EN_maxigp0_awready) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_awsize awsize() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_awuser awuser() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_awvalid awvalid() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method bid(maxigp0_bid) enable((*inhigh*) EN_maxigp0_bid) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_bready bready() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method bresp(maxigp0_bresp) enable((*inhigh*) EN_maxigp0_bresp) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method bvalid(maxigp0_bvalid) enable((*inhigh*) EN_maxigp0_bvalid) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method rdata(maxigp0_rdata) enable((*inhigh*) EN_maxigp0_rdata) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method rid(maxigp0_rid) enable((*inhigh*) EN_maxigp0_rid) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method rlast(maxigp0_rlast) enable((*inhigh*) EN_maxigp0_rlast) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_rready rready() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method rresp(maxigp0_rresp) enable((*inhigh*) EN_maxigp0_rresp) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method rvalid(maxigp0_rvalid) enable((*inhigh*) EN_maxigp0_rvalid) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_wdata wdata() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_wlast wlast() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method wready(maxigp0_wready) enable((*inhigh*) EN_maxigp0_wready) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_wstrb wstrb() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp0_wvalid wvalid() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
    endinterface
    interface Ps8Maxigp     maxigp2;
        method maxigp2_araddr araddr() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_arburst arburst() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_arcache arcache() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_arid arid() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_arlen arlen() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_arlock arlock() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_arprot arprot() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_arqos arqos() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method arready(maxigp2_arready) enable((*inhigh*) EN_maxigp2_arready) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_arsize arsize() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_aruser aruser() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_arvalid arvalid() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_awaddr awaddr() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_awburst awburst() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_awcache awcache() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_awid awid() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_awlen awlen() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_awlock awlock() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_awprot awprot() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_awqos awqos() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method awready(maxigp2_awready) enable((*inhigh*) EN_maxigp2_awready) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_awsize awsize() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_awuser awuser() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_awvalid awvalid() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method bid(maxigp2_bid) enable((*inhigh*) EN_maxigp2_bid) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_bready bready() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method bresp(maxigp2_bresp) enable((*inhigh*) EN_maxigp2_bresp) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method bvalid(maxigp2_bvalid) enable((*inhigh*) EN_maxigp2_bvalid) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method rdata(maxigp2_rdata) enable((*inhigh*) EN_maxigp2_rdata) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method rid(maxigp2_rid) enable((*inhigh*) EN_maxigp2_rid) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method rlast(maxigp2_rlast) enable((*inhigh*) EN_maxigp2_rlast) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_rready rready() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method rresp(maxigp2_rresp) enable((*inhigh*) EN_maxigp2_rresp) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method rvalid(maxigp2_rvalid) enable((*inhigh*) EN_maxigp2_rvalid) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_wdata wdata() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_wlast wlast() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method wready(maxigp2_wready) enable((*inhigh*) EN_maxigp2_wready) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_wstrb wstrb() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method maxigp2_wvalid wvalid() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
    endinterface
    interface Ps8Pl     pl;
        method pl_clk0 clk0() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method pl_clk1 clk1() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method ps_irq0(pl_ps_irq0) enable((*inhigh*) EN_pl_ps_irq0) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method pl_resetn0 resetn0() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
    endinterface
    schedule (maxigp0.araddr, maxigp0.arburst, maxigp0.arcache, maxigp0.arid, maxigp0.arlen, maxigp0.arlock, maxigp0.arprot, maxigp0.arqos, maxigp0.arready, maxigp0.arsize, maxigp0.aruser, maxigp0.arvalid, maxigp0.awaddr, maxigp0.awburst, maxigp0.awcache, maxigp0.awid, maxigp0.awlen, maxigp0.awlock, maxigp0.awprot, maxigp0.awqos, maxigp0.awready, maxigp0.awsize, maxigp0.awuser, maxigp0.awvalid, maxigp0.bid, maxigp0.bready, maxigp0.bresp, maxigp0.bvalid, maxigp0.rdata, maxigp0.rid, maxigp0.rlast, maxigp0.rready, maxigp0.rresp, maxigp0.rvalid, maxigp0.wdata, maxigp0.wlast, maxigp0.wready, maxigp0.wstrb, maxigp0.wvalid, maxigp2.araddr, maxigp2.arburst, maxigp2.arcache, maxigp2.arid, maxigp2.arlen, maxigp2.arlock, maxigp2.arprot, maxigp2.arqos, maxigp2.arready, maxigp2.arsize, maxigp2.aruser, maxigp2.arvalid, maxigp2.awaddr, maxigp2.awburst, maxigp2.awcache, maxigp2.awid, maxigp2.awlen, maxigp2.awlock, maxigp2.awprot, maxigp2.awqos, maxigp2.awready, maxigp2.awsize, maxigp2.awuser, maxigp2.awvalid, maxigp2.bid, maxigp2.bready, maxigp2.bresp, maxigp2.bvalid, maxigp2.rdata, maxigp2.rid, maxigp2.rlast, maxigp2.rready, maxigp2.rresp, maxigp2.rvalid, maxigp2.wdata, maxigp2.wlast, maxigp2.wready, maxigp2.wstrb, maxigp2.wvalid, pl.clk0, pl.clk1, pl.ps_irq0, pl.resetn0) CF (maxigp0.araddr, maxigp0.arburst, maxigp0.arcache, maxigp0.arid, maxigp0.arlen, maxigp0.arlock, maxigp0.arprot, maxigp0.arqos, maxigp0.arready, maxigp0.arsize, maxigp0.aruser, maxigp0.arvalid, maxigp0.awaddr, maxigp0.awburst, maxigp0.awcache, maxigp0.awid, maxigp0.awlen, maxigp0.awlock, maxigp0.awprot, maxigp0.awqos, maxigp0.awready, maxigp0.awsize, maxigp0.awuser, maxigp0.awvalid, maxigp0.bid, maxigp0.bready, maxigp0.bresp, maxigp0.bvalid, maxigp0.rdata, maxigp0.rid, maxigp0.rlast, maxigp0.rready, maxigp0.rresp, maxigp0.rvalid, maxigp0.wdata, maxigp0.wlast, maxigp0.wready, maxigp0.wstrb, maxigp0.wvalid, maxigp2.araddr, maxigp2.arburst, maxigp2.arcache, maxigp2.arid, maxigp2.arlen, maxigp2.arlock, maxigp2.arprot, maxigp2.arqos, maxigp2.arready, maxigp2.arsize, maxigp2.aruser, maxigp2.arvalid, maxigp2.awaddr, maxigp2.awburst, maxigp2.awcache, maxigp2.awid, maxigp2.awlen, maxigp2.awlock, maxigp2.awprot, maxigp2.awqos, maxigp2.awready, maxigp2.awsize, maxigp2.awuser, maxigp2.awvalid, maxigp2.bid, maxigp2.bready, maxigp2.bresp, maxigp2.bvalid, maxigp2.rdata, maxigp2.rid, maxigp2.rlast, maxigp2.rready, maxigp2.rresp, maxigp2.rvalid, maxigp2.wdata, maxigp2.wlast, maxigp2.wready, maxigp2.wstrb, maxigp2.wvalid, pl.clk0, pl.clk1, pl.ps_irq0, pl.resetn0);
endmodule
