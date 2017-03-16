
/*
   ../scripts/importbvi.py
   -c
   maxihpm0_fpd_aclk
   -c
   maxihpm0_fpd_aclk
   -c
   saxihpc0_fpd_aclk
   -c
   saxiacp_fpd_aclk
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
    method Action      rdata(Bit#(128) v);
    method Action      rid(Bit#(16) v);
    method Action      rlast(Bit#(1) v);
    method Bit#(1)     rready();
    method Action      rresp(Bit#(2) v);
    method Action      rvalid(Bit#(1) v);
    method Bit#(128)     wdata();
    method Bit#(1)     wlast();
    method Action      wready(Bit#(1) v);
    method Bit#(16)     wstrb();
    method Bit#(1)     wvalid();
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface Ps8Pl;
    method Action      acpinact(Bit#(1) v);
    method Bit#(1)     clk0();
    method Bit#(1)     clk1();
    method Action      ps_irq0(Bit#(1) v);
    method Bit#(1)     resetn0();
endinterface
(* always_ready, always_enabled *)
interface Ps8Saxiacp;
    method Action      araddr(Bit#(40) v);
    method Action      arburst(Bit#(2) v);
    method Action      arcache(Bit#(4) v);
    method Action      arid(Bit#(5) v);
    method Action      arlen(Bit#(8) v);
    method Action      arlock(Bit#(1) v);
    method Action      arprot(Bit#(3) v);
    method Action      arqos(Bit#(4) v);
    method Bit#(1)     arready();
    method Action      arsize(Bit#(3) v);
    method Action      aruser(Bit#(2) v);
    method Action      arvalid(Bit#(1) v);
    method Action      awaddr(Bit#(40) v);
    method Action      awburst(Bit#(2) v);
    method Action      awcache(Bit#(4) v);
    method Action      awid(Bit#(5) v);
    method Action      awlen(Bit#(8) v);
    method Action      awlock(Bit#(1) v);
    method Action      awprot(Bit#(3) v);
    method Action      awqos(Bit#(4) v);
    method Bit#(1)     awready();
    method Action      awsize(Bit#(3) v);
    method Action      awuser(Bit#(2) v);
    method Action      awvalid(Bit#(1) v);
    method Bit#(5)     bid();
    method Action      bready(Bit#(1) v);
    method Bit#(2)     bresp();
    method Bit#(1)     bvalid();
    method Bit#(128)     rdata();
    method Bit#(5)     rid();
    method Bit#(1)     rlast();
    method Action      rready(Bit#(1) v);
    method Bit#(2)     rresp();
    method Bit#(1)     rvalid();
    method Action      wdata(Bit#(128) v);
    method Action      wlast(Bit#(1) v);
    method Bit#(1)     wready();
    method Action      wstrb(Bit#(16) v);
    method Action      wvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface Ps8Saxigp;
    method Action      araddr(Bit#(49) v);
    method Action      arburst(Bit#(2) v);
    method Action      arcache(Bit#(4) v);
    method Action      arid(Bit#(6) v);
    method Action      arlen(Bit#(8) v);
    method Action      arlock(Bit#(1) v);
    method Action      arprot(Bit#(3) v);
    method Action      arqos(Bit#(4) v);
    method Bit#(1)     arready();
    method Action      arsize(Bit#(3) v);
    method Action      aruser(Bit#(1) v);
    method Action      arvalid(Bit#(1) v);
    method Action      awaddr(Bit#(49) v);
    method Action      awburst(Bit#(2) v);
    method Action      awcache(Bit#(4) v);
    method Action      awid(Bit#(6) v);
    method Action      awlen(Bit#(8) v);
    method Action      awlock(Bit#(1) v);
    method Action      awprot(Bit#(3) v);
    method Action      awqos(Bit#(4) v);
    method Bit#(1)     awready();
    method Action      awsize(Bit#(3) v);
    method Action      awuser(Bit#(1) v);
    method Action      awvalid(Bit#(1) v);
    method Bit#(6)     bid();
    method Action      bready(Bit#(1) v);
    method Bit#(2)     bresp();
    method Bit#(1)     bvalid();
    method Bit#(128)     rdata();
    method Bit#(6)     rid();
    method Bit#(1)     rlast();
    method Action      rready(Bit#(1) v);
    method Bit#(2)     rresp();
    method Bit#(1)     rvalid();
    method Action      wdata(Bit#(128) v);
    method Action      wlast(Bit#(1) v);
    method Bit#(1)     wready();
    method Action      wstrb(Bit#(16) v);
    method Action      wvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
(* always_ready, always_enabled *)
interface PS8;
    interface Ps8Maxigp     maxigp0;
    interface Ps8Maxigp     maxigp2;
    interface Ps8Pl     pl;
    interface Ps8Saxiacp     saxiacp;
    interface Ps8Saxigp     saxigp0;
endinterface
import "BVI" zynq_ultra_ps_e_0 =
module mkPS8#(Clock maxihpm0_fpd_aclk, Clock maxihpm0_lpd_aclk, Clock saxiacp_fpd_aclk, Clock saxihpc0_fpd_aclk)(PS8);
    default_clock no_clock;
    default_reset no_reset;
        input_clock maxihpm0_fpd_aclk(maxihpm0_fpd_aclk) = maxihpm0_fpd_aclk;
         /* from clock*/
        input_clock maxihpm0_lpd_aclk(maxihpm0_lpd_aclk) = maxihpm0_lpd_aclk;
         /* from clock*/
        input_clock saxiacp_fpd_aclk(saxiacp_fpd_aclk) = saxiacp_fpd_aclk;
         /* from clock*/
        input_clock saxihpc0_fpd_aclk(saxihpc0_fpd_aclk) = saxihpc0_fpd_aclk;
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
        method acpinact(pl_acpinact) enable((*inhigh*) EN_pl_acpinact) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method pl_clk0 clk0() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method pl_clk1 clk1() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method ps_irq0(pl_ps_irq0) enable((*inhigh*) EN_pl_ps_irq0) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method pl_resetn0 resetn0() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
    endinterface
    interface Ps8Saxiacp     saxiacp;
       method araddr(saxiacp_araddr) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_araddr);
       method arburst(saxiacp_arburst) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_arburst);
       method arcache(saxiacp_arcache) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_arcache);
       method arid(saxiacp_arid) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_arid);
       method arlen(saxiacp_arlen) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_arlen);
       method arlock(saxiacp_arlock) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_arlock);
       method arprot(saxiacp_arprot) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_arprot);
       method arqos(saxiacp_arqos) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_arqos);
       method saxiacp_arready arready() clocked_by (saxiacp_fpd_aclk) reset_by(no_reset);
       method arsize(saxiacp_arsize) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_arsize);
       method aruser(saxiacp_aruser) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_aruser);
       method arvalid(saxiacp_arvalid) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_arvalid);
       method awaddr(saxiacp_awaddr) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_awaddr);
       method awburst(saxiacp_awburst) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_awburst);
       method awcache(saxiacp_awcache) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_awcache);
       method awid(saxiacp_awid) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_awid);
       method awlen(saxiacp_awlen) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_awlen);
       method awlock(saxiacp_awlock) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_awlock);
       method awprot(saxiacp_awprot) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_awprot);
       method awqos(saxiacp_awqos) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_awqos);
       method saxiacp_awready awready() clocked_by (saxiacp_fpd_aclk) reset_by(no_reset);
       method awsize(saxiacp_awsize) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_awsize);
       method awuser(saxiacp_awuser) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_awuser);
       method awvalid(saxiacp_awvalid) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_awvalid);
       method saxiacp_bid bid() clocked_by (saxiacp_fpd_aclk) reset_by(no_reset);
       method bready(saxiacp_bready) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_bready);
       method saxiacp_bresp bresp() clocked_by (saxiacp_fpd_aclk) reset_by(no_reset);
       method saxiacp_bvalid bvalid() clocked_by (saxiacp_fpd_aclk) reset_by(no_reset);
       method saxiacp_rdata rdata() clocked_by (saxiacp_fpd_aclk) reset_by(no_reset);
       method saxiacp_rid rid() clocked_by (saxiacp_fpd_aclk) reset_by(no_reset);
       method saxiacp_rlast rlast() clocked_by (saxiacp_fpd_aclk) reset_by(no_reset);
       method rready(saxiacp_rready) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_rready);
       method saxiacp_rresp rresp() clocked_by (saxiacp_fpd_aclk) reset_by(no_reset);
       method saxiacp_rvalid rvalid() clocked_by (saxiacp_fpd_aclk) reset_by(no_reset);
       method wdata(saxiacp_wdata) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_wdata);
       method wlast(saxiacp_wlast) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_wlast);
       method saxiacp_wready wready() clocked_by (saxiacp_fpd_aclk) reset_by(no_reset);
       method wstrb(saxiacp_wstrb) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_wstrb);
       method wvalid(saxiacp_wvalid) clocked_by (saxiacp_fpd_aclk) reset_by(no_reset) enable((*inhigh*) EN_saxiacp_wvalid);
    endinterface
    interface Ps8Saxigp     saxigp0;
        method araddr(saxigp0_araddr) enable((*inhigh*) EN_saxigp0_araddr) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method arburst(saxigp0_arburst) enable((*inhigh*) EN_saxigp0_arburst) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method arcache(saxigp0_arcache) enable((*inhigh*) EN_saxigp0_arcache) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method arid(saxigp0_arid) enable((*inhigh*) EN_saxigp0_arid) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method arlen(saxigp0_arlen) enable((*inhigh*) EN_saxigp0_arlen) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method arlock(saxigp0_arlock) enable((*inhigh*) EN_saxigp0_arlock) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method arprot(saxigp0_arprot) enable((*inhigh*) EN_saxigp0_arprot) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method arqos(saxigp0_arqos) enable((*inhigh*) EN_saxigp0_arqos) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method saxigp0_arready arready() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method arsize(saxigp0_arsize) enable((*inhigh*) EN_saxigp0_arsize) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method aruser(saxigp0_aruser) enable((*inhigh*) EN_saxigp0_aruser) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method arvalid(saxigp0_arvalid) enable((*inhigh*) EN_saxigp0_arvalid) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method awaddr(saxigp0_awaddr) enable((*inhigh*) EN_saxigp0_awaddr) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method awburst(saxigp0_awburst) enable((*inhigh*) EN_saxigp0_awburst) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method awcache(saxigp0_awcache) enable((*inhigh*) EN_saxigp0_awcache) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method awid(saxigp0_awid) enable((*inhigh*) EN_saxigp0_awid) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method awlen(saxigp0_awlen) enable((*inhigh*) EN_saxigp0_awlen) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method awlock(saxigp0_awlock) enable((*inhigh*) EN_saxigp0_awlock) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method awprot(saxigp0_awprot) enable((*inhigh*) EN_saxigp0_awprot) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method awqos(saxigp0_awqos) enable((*inhigh*) EN_saxigp0_awqos) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method saxigp0_awready awready() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method awsize(saxigp0_awsize) enable((*inhigh*) EN_saxigp0_awsize) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method awuser(saxigp0_awuser) enable((*inhigh*) EN_saxigp0_awuser) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method awvalid(saxigp0_awvalid) enable((*inhigh*) EN_saxigp0_awvalid) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method saxigp0_bid bid() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method bready(saxigp0_bready) enable((*inhigh*) EN_saxigp0_bready) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method saxigp0_bresp bresp() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method saxigp0_bvalid bvalid() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method saxigp0_rdata rdata() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method saxigp0_rid rid() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method saxigp0_rlast rlast() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method rready(saxigp0_rready) enable((*inhigh*) EN_saxigp0_rready) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method saxigp0_rresp rresp() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method saxigp0_rvalid rvalid() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method wdata(saxigp0_wdata) enable((*inhigh*) EN_saxigp0_wdata) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method wlast(saxigp0_wlast) enable((*inhigh*) EN_saxigp0_wlast) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method saxigp0_wready wready() clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method wstrb(saxigp0_wstrb) enable((*inhigh*) EN_saxigp0_wstrb) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
        method wvalid(saxigp0_wvalid) enable((*inhigh*) EN_saxigp0_wvalid) clocked_by (maxihpm0_lpd_aclk) reset_by (no_reset);
    endinterface
    schedule (maxigp0.araddr, maxigp0.arburst, maxigp0.arcache, maxigp0.arid, maxigp0.arlen, maxigp0.arlock, maxigp0.arprot, maxigp0.arqos, maxigp0.arready, maxigp0.arsize, maxigp0.aruser, maxigp0.arvalid, maxigp0.awaddr, maxigp0.awburst, maxigp0.awcache, maxigp0.awid, maxigp0.awlen, maxigp0.awlock, maxigp0.awprot, maxigp0.awqos, maxigp0.awready, maxigp0.awsize, maxigp0.awuser, maxigp0.awvalid, maxigp0.bid, maxigp0.bready, maxigp0.bresp, maxigp0.bvalid, maxigp0.rdata, maxigp0.rid, maxigp0.rlast, maxigp0.rready, maxigp0.rresp, maxigp0.rvalid, maxigp0.wdata, maxigp0.wlast, maxigp0.wready, maxigp0.wstrb, maxigp0.wvalid, maxigp2.araddr, maxigp2.arburst, maxigp2.arcache, maxigp2.arid, maxigp2.arlen, maxigp2.arlock, maxigp2.arprot, maxigp2.arqos, maxigp2.arready, maxigp2.arsize, maxigp2.aruser, maxigp2.arvalid, maxigp2.awaddr, maxigp2.awburst, maxigp2.awcache, maxigp2.awid, maxigp2.awlen, maxigp2.awlock, maxigp2.awprot, maxigp2.awqos, maxigp2.awready, maxigp2.awsize, maxigp2.awuser, maxigp2.awvalid, maxigp2.bid, maxigp2.bready, maxigp2.bresp, maxigp2.bvalid, maxigp2.rdata, maxigp2.rid, maxigp2.rlast, maxigp2.rready, maxigp2.rresp, maxigp2.rvalid, maxigp2.wdata, maxigp2.wlast, maxigp2.wready, maxigp2.wstrb, maxigp2.wvalid, pl.acpinact, pl.clk0, pl.clk1, pl.ps_irq0, pl.resetn0, saxiacp.araddr, saxiacp.arburst, saxiacp.arcache, saxiacp.arid, saxiacp.arlen, saxiacp.arlock, saxiacp.arprot, saxiacp.arqos, saxiacp.arready, saxiacp.arsize, saxiacp.aruser, saxiacp.arvalid, saxiacp.awaddr, saxiacp.awburst, saxiacp.awcache, saxiacp.awid, saxiacp.awlen, saxiacp.awlock, saxiacp.awprot, saxiacp.awqos, saxiacp.awready, saxiacp.awsize, saxiacp.awuser, saxiacp.awvalid, saxiacp.bid, saxiacp.bready, saxiacp.bresp, saxiacp.bvalid, saxiacp.rdata, saxiacp.rid, saxiacp.rlast, saxiacp.rready, saxiacp.rresp, saxiacp.rvalid, saxiacp.wdata, saxiacp.wlast, saxiacp.wready, saxiacp.wstrb, saxiacp.wvalid, saxigp0.araddr, saxigp0.arburst, saxigp0.arcache, saxigp0.arid, saxigp0.arlen, saxigp0.arlock, saxigp0.arprot, saxigp0.arqos, saxigp0.arready, saxigp0.arsize, saxigp0.aruser, saxigp0.arvalid, saxigp0.awaddr, saxigp0.awburst, saxigp0.awcache, saxigp0.awid, saxigp0.awlen, saxigp0.awlock, saxigp0.awprot, saxigp0.awqos, saxigp0.awready, saxigp0.awsize, saxigp0.awuser, saxigp0.awvalid, saxigp0.bid, saxigp0.bready, saxigp0.bresp, saxigp0.bvalid, saxigp0.rdata, saxigp0.rid, saxigp0.rlast, saxigp0.rready, saxigp0.rresp, saxigp0.rvalid, saxigp0.wdata, saxigp0.wlast, saxigp0.wready, saxigp0.wstrb, saxigp0.wvalid) CF (maxigp0.araddr, maxigp0.arburst, maxigp0.arcache, maxigp0.arid, maxigp0.arlen, maxigp0.arlock, maxigp0.arprot, maxigp0.arqos, maxigp0.arready, maxigp0.arsize, maxigp0.aruser, maxigp0.arvalid, maxigp0.awaddr, maxigp0.awburst, maxigp0.awcache, maxigp0.awid, maxigp0.awlen, maxigp0.awlock, maxigp0.awprot, maxigp0.awqos, maxigp0.awready, maxigp0.awsize, maxigp0.awuser, maxigp0.awvalid, maxigp0.bid, maxigp0.bready, maxigp0.bresp, maxigp0.bvalid, maxigp0.rdata, maxigp0.rid, maxigp0.rlast, maxigp0.rready, maxigp0.rresp, maxigp0.rvalid, maxigp0.wdata, maxigp0.wlast, maxigp0.wready, maxigp0.wstrb, maxigp0.wvalid, maxigp2.araddr, maxigp2.arburst, maxigp2.arcache, maxigp2.arid, maxigp2.arlen, maxigp2.arlock, maxigp2.arprot, maxigp2.arqos, maxigp2.arready, maxigp2.arsize, maxigp2.aruser, maxigp2.arvalid, maxigp2.awaddr, maxigp2.awburst, maxigp2.awcache, maxigp2.awid, maxigp2.awlen, maxigp2.awlock, maxigp2.awprot, maxigp2.awqos, maxigp2.awready, maxigp2.awsize, maxigp2.awuser, maxigp2.awvalid, maxigp2.bid, maxigp2.bready, maxigp2.bresp, maxigp2.bvalid, maxigp2.rdata, maxigp2.rid, maxigp2.rlast, maxigp2.rready, maxigp2.rresp, maxigp2.rvalid, maxigp2.wdata, maxigp2.wlast, maxigp2.wready, maxigp2.wstrb, maxigp2.wvalid, pl.acpinact, pl.clk0, pl.clk1, pl.ps_irq0, pl.resetn0, saxiacp.araddr, saxiacp.arburst, saxiacp.arcache, saxiacp.arid, saxiacp.arlen, saxiacp.arlock, saxiacp.arprot, saxiacp.arqos, saxiacp.arready, saxiacp.arsize, saxiacp.aruser, saxiacp.arvalid, saxiacp.awaddr, saxiacp.awburst, saxiacp.awcache, saxiacp.awid, saxiacp.awlen, saxiacp.awlock, saxiacp.awprot, saxiacp.awqos, saxiacp.awready, saxiacp.awsize, saxiacp.awuser, saxiacp.awvalid, saxiacp.bid, saxiacp.bready, saxiacp.bresp, saxiacp.bvalid, saxiacp.rdata, saxiacp.rid, saxiacp.rlast, saxiacp.rready, saxiacp.rresp, saxiacp.rvalid, saxiacp.wdata, saxiacp.wlast, saxiacp.wready, saxiacp.wstrb, saxiacp.wvalid, saxigp0.araddr, saxigp0.arburst, saxigp0.arcache, saxigp0.arid, saxigp0.arlen, saxigp0.arlock, saxigp0.arprot, saxigp0.arqos, saxigp0.arready, saxigp0.arsize, saxigp0.aruser, saxigp0.arvalid, saxigp0.awaddr, saxigp0.awburst, saxigp0.awcache, saxigp0.awid, saxigp0.awlen, saxigp0.awlock, saxigp0.awprot, saxigp0.awqos, saxigp0.awready, saxigp0.awsize, saxigp0.awuser, saxigp0.awvalid, saxigp0.bid, saxigp0.bready, saxigp0.bresp, saxigp0.bvalid, saxigp0.rdata, saxigp0.rid, saxigp0.rlast, saxigp0.rready, saxigp0.rresp, saxigp0.rvalid, saxigp0.wdata, saxigp0.wlast, saxigp0.wready, saxigp0.wstrb, saxigp0.wvalid);
endmodule
