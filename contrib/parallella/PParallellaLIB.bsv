// Copyright (c) 2015 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// This file is a hand-generated file that we hope will someday be
// generated automatically by connectal/generated/scripts/importbvi.py
//
// Created by copying the style of connectal/generated/xilinx/PPS7LIB.bsv

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;


// The name of this interface is a prefix "Par_" plus the common prefix of the signals "txo"
// Hopefully this is what importbvi.py would do
(* always_ready, always_enabled *)
interface Par_txo;
   method Action data_p(Bit#(8) v);
   method Action data_n(Bit#(8) v);
   method Action frame_p(Bit#(1) v);
   method Action frame_n(Bit#(1) v);
   method Action lclk_p(Bit#(1) v);
   method Action lclk_n(Bit#(1) v);
endinterface

(* always_ready, always_enabled *)
interface Par_txi; 
   method Bit#(1) wr_wait_p();
   method Bit#(1) wr_wait_n();
   method Bit#(1) rd_wait_p();
   method Bit#(1) rd_wait_n();
endinterface

(* always_ready, always_enabled *)
interface Par_rxi;
   method Bit#(8) data_p();
   method Bit#(8) data_n();
   method Bit#(1) frame_p();
   method Bit#(1) frame_n();
   method Bit#(1) lclk_p();
   method Bit#(1) lclk_n();
   method Action cclk_p(Bit#(1) v);
   method Action cclk_n(Bit#(1) v);
endinterface

(* always_ready, always_enabled *)
interface Par_rxo;
   method Action wr_wait_p(Bit#(1) v);
   method Action wr_wait_n(Bit#(1) v);
   method Action rd_wait_p(Bit#(1) v);
   method Action rd_wait_n(Bit#(1) v);
endinterface

(* always_ready, always_enabled *)
interface Par_misc;
   method Bit#(1) csysack();
   method Bit#(1) cactive();
   method Action csysreq(Bit#(1) v);
   method Bit#(1) reset_chip();
   method Bit#(1) reset_fpga();
endinterface

typedef AxiMasterBits#(32,64,6,Empty) ParSaxiHp;
typedef AxiSlaveBits#(32,32,12,Empty) ParMaxiGp;

(* always_ready, always_enabled *)
interface PParallellaLIB;
   interface Par_txo txo;
   interface Par_txi txi;
   interface Par_rxo rxo;
   interface Par_rxi rxi;
   interface ParMaxiGp maxi;   // this will connect to a master
   interface ParSaxiHp saxi;  // this will connect to a slave
   interface Par_misc misc;
endinterface

import "BVI" parallella =
module mkPParallellaLIB#(Clock maxiclk, Clock saxiclk, 
   Reset maxiclk_reset, Reset saxiclk_reset,
   Reset maxireset, Reset saxireset,
   Reset reset_chip, Reset reset_fpga)(PParallellaLIB);
   // default_clock clk();
   // default_reset rst();
   input_clock maxiclk(emaxi_aclk) = maxiclk;  // assigns the verilog emaxi_aclk
   input_clock saxiclk(esaxi_aclk) = saxiclk;  // assigns the verilog esaxi_aclk
   input_reset maxiclk_reset() = maxiclk_reset; /* from clock*/
   input_reset saxiclk_reset() = saxiclk_reset; /* from clock*/
   input_reset maxireset() = maxireset;
   input_reset saxireset() = saxireset;
   
   interface Par_misc misc;
      method csysack csysack();
      method cactive cactive();
      method reset_chip reset_chip();
      method reset_fpga reset_fpga();
      method csysreq(csysreq) enable((*inhigh*) EN_csysreq);
   endinterface
   
   interface Par_txo txo;
      method data_p(txo_data_p) enable((*inhigh*) EN_txo_data_p);
      method data_n(txo_data_n) enable((*inhigh*) EN_txo_data_n);
      method frame_p(txo_frame_p) enable((*inhigh*) EN_txo_frame_p);
      method frame_n(txo_frame_n) enable((*inhigh*) EN_txo_frame_n);
      method lclk_p(txo_lclk_p) enable((*inhigh*) EN_txo_lclk_p);
      method lclk_n(txo_lclk_n) enable((*inhigh*) EN_txo_lclk_n);
   endinterface

   interface Par_txi txi;
      method txo_wr_wait_p wr_wait_p();
      method txo_wr_wait_n wr_wait_n();
      method txo_rd_wait_p rd_wait_p();
      method txo_rd_wait_n rd_wait_n();
   endinterface

   interface Par_rxi rxi;
      method rxi_data_p data_p();
      method rxi_data_n data_n();
      method rxi_frame_p frame_p();
      method rxi_frame_n frame_n();
      method rxi_lclk_p lclk_p();
      method rxi_lclk_n lclk_n();
      method cclk_p(rxi_cclk_p) enable((*inhigh*) EN_rxi_cclk_p);
      method cclk_n(rxi_cclk_n) enable((*inhigh*) EN_rxi_cclk_n);
   endinterface
 
   interface Par_rxo rxo;
      method wr_wait_p(rxo_wr_wait_p) enable((*inhigh*) EN_rxo_wr_wait_p);
      method wr_wait_n(rxo_wr_wait_n) enable((*inhigh*) EN_rxo_wr_wait_n);
      method rd_wait_p(rxo_rd_wait_p) enable((*inhigh*) EN_rxo_rd_wait_p);
      method rd_wait_n(rxo_rd_wait_n) enable((*inhigh*) EN_rxo_rd_wait_n);
   endinterface
   
   interface ParSaxiHp saxi;
      method esaxi_araddr araddr() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_arburst arburst() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_arcache arcache() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_aresetn aresetn() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_arid arid() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_arlen arlen() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_arlock arlock() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_arprot arprot() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_arqos arqos() clocked_by (saxiclk) reset_by(saxireset);
      method arready(esaxi_arready)  clocked_by (saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_arready);
      method esaxi_arsize arsize() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_arvalid arvalid() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_awaddr awaddr() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_awburst awburst() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_awcache awcache() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_awid awid() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_awlen awlen() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_awlock awlock() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_awprot awprot() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_awqos awqos() clocked_by (saxiclk) reset_by(saxireset);
      method awready(esaxi_awready)  clocked_by (saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_awready);
      method esaxi_awsize awsize() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_awvalid awvalid() clocked_by (saxiclk) reset_by(saxireset);
      method bid(esaxi_bid) enable((*inhigh*) EN_esaxi_bid);
      method esaxi_bready bready() clocked_by (saxiclk) reset_by(saxireset);
      method bresp(esaxi_bresp)  clocked_by (saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_bresp);
      method bvalid(esaxi_bvalid)  clocked_by (saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_bvalid);
      method rdata(esaxi_rdata)  clocked_by (saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_rdata);
      method rid(esaxi_rid)  clocked_by (saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_rid);
      method rlast(esaxi_rlast)  clocked_by (saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_rlast);
      method esaxi_rready rready() clocked_by (saxiclk) reset_by(saxireset);
      method rresp(esaxi_rresp)  clocked_by (saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_rresp);
      method rvalid(esaxi_rvalid)  clocked_by (saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_rvalid);
      method esaxi_wdata wdata() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_wid wid() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_wlast wlast() clocked_by (saxiclk) reset_by(saxireset);
      method wready(esaxi_wready)  clocked_by (saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_wready);
      method esaxi_wstrb wstrb() clocked_by (saxiclk) reset_by(saxireset);
      method esaxi_wvalid wvalid() clocked_by (saxiclk) reset_by(saxireset);
   endinterface   
   
   interface ParMaxiGp maxi;
      method araddr(emaxi_araddr) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_araddr);
      method arburst(emaxi_arburst) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_arburst);
      method arcache(emaxi_arcache) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_arcache);
      method emaxi_aresetn aresetn() clocked_by(maxiclk) reset_by(maxireset);
      method arid(emaxi_arid) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_arid);
      method arlen(emaxi_arlen) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_arlen);
      method arlock(emaxi_arlock) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_arlock);
      method arprot(emaxi_arprot) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_arprot);
      method arqos(emaxi_arqos) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_arqos);
      method emaxi_arready arready() clocked_by(maxiclk) reset_by(maxireset);
      method arsize(emaxi_arsize) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_arsize);
      method arvalid(emaxi_arvalid) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_arvalid);
      method awaddr(emaxi_awaddr) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_awaddr);
      method awburst(emaxi_awburst) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_awburst);
      method awcache(emaxi_awcache) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_awcache);
      method awid(emaxi_awid) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_awid);
      method awlen(emaxi_awlen) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_awlen);
      method awlock(emaxi_awlock) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_awlock);
      method awprot(emaxi_awprot) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_awprot);
      method awqos(emaxi_awqos) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_awqos);
      method emaxi_awready awready() clocked_by(maxiclk) reset_by(maxireset);
      method awsize(emaxi_awsize) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_awsize);
      method awvalid(emaxi_awvalid) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_awvalid);
      method emaxi_bid bid() clocked_by(maxiclk) reset_by(maxireset);
      method bready(emaxi_bready) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_bready);
      method emaxi_bresp bresp() clocked_by(maxiclk) reset_by(maxireset);
      method emaxi_bvalid bvalid() clocked_by(maxiclk) reset_by(maxireset);
      method emaxi_rdata rdata() clocked_by(maxiclk) reset_by(maxireset);
      method emaxi_rlast rlast() clocked_by(maxiclk) reset_by(maxireset);
      method rready(emaxi_rready) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_rready);
      method emaxi_rresp rresp() clocked_by(maxiclk) reset_by(maxireset);
      method emaxi_rvalid rvalid() clocked_by(maxiclk) reset_by(maxireset);
      method wdata(emaxi_wdata) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_wdata);
      method wid(emaxi_wid) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_wid);
      method wlast(emaxi_wlast) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_wlast);
      method emaxi_wready wready() clocked_by(maxiclk) reset_by(maxireset);
      method wstrb(emaxi_wstrb) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_wstrb);
      method wvalid(emaxi_wvalid) clocked_by(maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_wvalid);
      method emaxi_rid rid() clocked_by(maxiclk) reset_by(maxireset);
   endinterface
   
   
schedule (
   misc.csysack, misc.cactive, misc.reset_chip, misc.reset_fpga, txo.data_p, txo.data_n,
   txo.frame_p, txo.frame_n, txo.lclk_p, txo.lclk_n, rxo.wr_wait_p,
   rxo.wr_wait_n, rxo.rd_wait_p, rxo.rd_wait_n, rxi.cclk_p,
   rxi.cclk_n, maxi.awid, maxi.awaddr, maxi.awlen, maxi.awsize,
   maxi.awburst, maxi.awlock, maxi.awcache, maxi.awprot,
   maxi.awvalid, saxi.awready, maxi.wid, maxi.wdata, maxi.wstrb,
   maxi.wlast, maxi.wvalid, saxi.wready, maxi.bready, saxi.bid,
   saxi.bresp, saxi.bvalid, maxi.arid, maxi.araddr, maxi.arlen,
   maxi.arsize, maxi.arburst, maxi.arlock, maxi.arcache,
   maxi.arprot, maxi.arvalid, saxi.arready, maxi.rready,
   saxi.rid, saxi.rdata, saxi.rresp, saxi.rlast, saxi.rvalid,
   maxi.awqos, maxi.arqos,
   // Inputs
   // clkin_100, saxi.aclk, maxi.aclk, reset, 
   saxi.aresetn,
   maxi.aresetn, misc.csysreq, rxi.data_p, rxi.data_n, rxi.frame_p,
   rxi.frame_n, rxi.lclk_p, rxi.lclk_n, txi.wr_wait_p, txi.wr_wait_n,
   txi.rd_wait_p, txi.rd_wait_n, maxi.awready, saxi.awid,
   saxi.awaddr, saxi.awlen, saxi.awsize, saxi.awburst,
   saxi.awlock, saxi.awcache, saxi.awprot, saxi.awvalid,
   maxi.wready, saxi.wid, saxi.wdata, saxi.wstrb, saxi.wlast,
   saxi.wvalid, maxi.bid, maxi.bresp, maxi.bvalid, saxi.bready,
   maxi.arready, saxi.arid, saxi.araddr, saxi.arlen, saxi.arsize,
   saxi.arburst, saxi.arlock, saxi.arcache, saxi.arprot,
   saxi.arvalid, maxi.rid, maxi.rdata, maxi.rresp, maxi.rlast,
   maxi.rvalid, saxi.rready, saxi.awqos, saxi.arqos
) CF (
   misc.csysack, misc.cactive, misc.reset_chip, misc.reset_fpga, txo.data_p, txo.data_n,
   txo.frame_p, txo.frame_n, txo.lclk_p, txo.lclk_n, rxo.wr_wait_p,
   rxo.wr_wait_n, rxo.rd_wait_p, rxo.rd_wait_n, rxi.cclk_p,
   rxi.cclk_n, maxi.awid, maxi.awaddr, maxi.awlen, maxi.awsize,
   maxi.awburst, maxi.awlock, maxi.awcache, maxi.awprot,
   maxi.awvalid, saxi.awready, maxi.wid, maxi.wdata, maxi.wstrb,
   maxi.wlast, maxi.wvalid, saxi.wready, maxi.bready, saxi.bid,
   saxi.bresp, saxi.bvalid, maxi.arid, maxi.araddr, maxi.arlen,
   maxi.arsize, maxi.arburst, maxi.arlock, maxi.arcache,
   maxi.arprot, maxi.arvalid, saxi.arready, maxi.rready,
   saxi.rid, saxi.rdata, saxi.rresp, saxi.rlast, saxi.rvalid,
   maxi.awqos, maxi.arqos,
   // Inputs
   // clkin_100, saxi.aclk, maxi.aclk, reset, 
   saxi.aresetn,
   maxi.aresetn, misc.csysreq, rxi.data_p, rxi.data_n, rxi.frame_p,
   rxi.frame_n, rxi.lclk_p, rxi.lclk_n, txi.wr_wait_p, txi.wr_wait_n,
   txi.rd_wait_p, txi.rd_wait_n, maxi.awready, saxi.awid,
   saxi.awaddr, saxi.awlen, saxi.awsize, saxi.awburst,
   saxi.awlock, saxi.awcache, saxi.awprot, saxi.awvalid,
   maxi.wready, saxi.wid, saxi.wdata, saxi.wstrb, saxi.wlast,
   saxi.wvalid, maxi.bid, maxi.bresp, maxi.bvalid, saxi.bready,
   maxi.arready, saxi.arid, saxi.araddr, saxi.arlen, saxi.arsize,
   saxi.arburst, saxi.arlock, saxi.arcache, saxi.arprot,
   saxi.arvalid, maxi.rid, maxi.rdata, maxi.rresp, maxi.rlast,
   maxi.rvalid, saxi.rready, saxi.awqos, saxi.arqos
   
   );

endmodule
