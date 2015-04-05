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
interface Par_txo;
   method Action data_p(Bit#(8) v);
   method Action data_n(Bit#(8) v);
   method Action frame_p(Bit#(1) v);
   method Action frame_n(Bit#(1) v);
   method Action lclk_p(Bit#(1) v);
   method Action lclk_n(Bit#(1) v);
endinterface

interface Par_txi; 
   method Bit#(1) wr_wait_p();
   method Bit#(1) wr_wait_n();
   method Bit#(1) rd_wait_p();
   method Bit#(1) rd_wait_n();
endinterface

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

interface Par_rxo;
   method Action wr_wait_p(Bit#(1) v);
   method Action wr_wait_n(Bit#(1) v);
   method Action rd_wait_p(Bit#(1) v);
   method Action rd_wait_n(Bit#(1) v);
endinterface

interface Par_misc;
   method Bit#(1) cactive();
   method Bit#(1) csysack();
   method Action reset_chip();
   method Action reset_fpga();
endinterface

interface PParallellaLib;
   interface Par_txo txo;
   interface Par_txi txi;
   interface Par_rxo rxo;
   interface Par_rxi rxi;
   interface AxiSlaveBits#(32,32,12) maxi;   // this will connect to a master
   interface AxiMasterBits#(32,64,6) saxi;  // this will connect to a slave
   interface Par_misc misc;
endinterface

import "BVI" PParallella =
module mkPParallellaLIB#(Clock maxiclk, Clock saxiclk, 
   Reset maxiclk_reset, Reset saxiclk_reset,
   Reset maxireset, Reset saxireset,
   Reset reset_chip, Reset reset_fpga)(PParallellaLib);
   // default_clock clk();
   // default_reset rst();
   input_clock maxiclk(emaxi_aclk) = maxiclk;  // assigns the verilog emaxi_aclk
   input_clock saxiclk(esaxi_aclk) = saxiclk;  // assigns the verilog esaxi_aclk
   input_reset maxiclk_reset() = maxiclk_reset; /* from clock*/
   input_reset saxiclk_reset() = saxiclk_reset; /* from clock*/
   
   interface Par_misc misc;
      method cactive(cactive);
      method csysack(csysack);
      method reset_chip(reset_chip) enable((*inhigh*) EN_reset_chip);
      method reset_fpga(reset_fpga) enable((*inhigh*) EN_reset_fpga);
   endinterface
   
   interface Par_txo txo;
      method data_p(txo_data_p) enable((*inhigh*) EN_txo_data_p);
      method data_n(txo_data_n) enable((*inhigh*) EN_txo_data_n);
      method frame_p(txo_frame_p) enable((*inhigh*) EN_txo_frame_p);
      method frame_n(txo_frame_n) enable((*inhigh*) EN_txo_frame_n);
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
   endinterface
 
   interface Par_rxo rxo;
      method wr_wait_p(rxo_wr_wait_p) enable((*inhigh*) EN_rxo_wr_wait_p);
      method wr_wait_n(rxo_wr_wait_n) enable((*inhigh*) EN_rxo_wr_wait_n);
      method rd_wait_p(rxo_rd_wait_p) enable((*inhigh*) EN_rxo_rd_wait_p);
      method rd_wait_n(rxo_rd_wait_n) enable((*inhigh*) EN_rxo_rd_wait_n);
      method cclk_p(rxi_cclk_p) enable((*inhigh*) EN_rxi_cclk_p);
      method cclk_n(rxi_cclk_n) enable((*inhigh*) EN_rxi_cclk_n);
   endinterface
   
   interface Par_emaxi maxi;
      method emaxi_araddr araddr() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_arburst arburst() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_arcache arcache() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_aresetn aresetn() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_arid arid() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_arlen arlen() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_arlock arlock() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_arprot arprot() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_arqos arqos() clocked_by (maxiclk) reset_by(maxireset);
      method arready(emaxi_arready)  clocked_by (maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_arready);
      method emaxi_arsize arsize() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_arvalid arvalid() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_awaddr awaddr() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_awburst awburst() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_awcache awcache() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_awid awid() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_awlen awlen() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_awlock awlock() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_awprot awprot() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_awqos awqos() clocked_by (maxiclk) reset_by(maxireset);
      method awready(emaxi_awready)  clocked_by (maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_awready);
      method emaxi_awsize awsize() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_awvalid awvalid() clocked_by (maxiclk) reset_by(maxireset);
      method bid(emaxi_bid) enable((*inhigh*) EN_emaxi_bid);
      method emaxi_bready bready() clocked_by (maxiclk) reset_by(maxireset);
      method bresp(emaxi_bresp)  clocked_by (maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_bresp);
      method bvalid(emaxi_bvalid)  clocked_by (maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_bvalid);
      method rdata(emaxi_rdata)  clocked_by (maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_rdata);
      method rid(emaxi_rid)  clocked_by (maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_rid);
      method rlast(emaxi_rlast)  clocked_by (maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_rlast);
      method emaxi_rready rready() clocked_by (maxiclk) reset_by(maxireset);
      method rresp(emaxi_rresp)  clocked_by (maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_rresp);
      method rvalid(emaxi_rvalid)  clocked_by (maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_rvalid);
      method emaxi_wdata wdata() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_wid wid() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_wlast wlast() clocked_by (maxiclk) reset_by(maxireset);
      method wready(emaxi_wready)  clocked_by (maxiclk) reset_by(maxireset) enable((*inhigh*) EN_emaxi_wready);
      method emaxi_wstrb wstrb() clocked_by (maxiclk) reset_by(maxireset);
      method emaxi_wvalid wvalid() clocked_by (maxiclk) reset_by(maxireset);
   endinterface   
   
   
   
   
   interface Par_saxi saxi;
      method araddr(esaxi_araddr) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_araddr);
      method arburst(esaxi_arburst) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_arburst);
      method arcache(esaxi_arcache) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_arcache);
      method esaxi_aresetn aresetn() clocked_by(saxiclk) reset_by(saxireset);
      method arid(esaxi_arid) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_arid);
      method arlen(esaxi_arlen) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_arlen);
      method arlock(esaxi_arlock) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_arlock);
      method arprot(esaxi_arprot) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_arprot);
      method arqos(esaxi_arqos) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_arqos);
      method esaxi_arready arready() clocked_by(saxiclk) reset_by(saxireset);
      method arsize(esaxi_arsize) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_arsize);
      method arvalid(esaxi_arvalid) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_arvalid);
      method awaddr(esaxi_awaddr) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_awaddr);
      method awburst(esaxi_awburst) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_awburst);
      method awcache(esaxi_awcache) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_awcache);
      method awid(esaxi_awid) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_awid);
      method awlen(esaxi_awlen) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_awlen);
      method awlock(esaxi_awlock) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_awlock);
      method awprot(esaxi_awprot) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_awprot);
      method awqos(esaxi_awqos) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_awqos);
      method esaxi_awready awready() clocked_by(saxiclk) reset_by(saxireset);
      method awsize(esaxi_awsize) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_awsize);
      method awvalid(esaxi_awvalid) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_awvalid);
      method esaxi_bid bid() clocked_by(saxiclk) reset_by(saxireset);
      method bready(esaxi_bready) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_bready);
      method esaxi_bresp bresp() clocked_by(saxiclk) reset_by(saxireset);
      method esaxi_bvalid bvalid() clocked_by(saxiclk) reset_by(saxireset);
      method esaxi_rdata rdata() clocked_by(saxiclk) reset_by(saxireset);
      method esaxi_rlast rlast() clocked_by(saxiclk) reset_by(saxireset);
      method rready(esaxi_rready) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_rready);
      method esaxi_rresp rresp() clocked_by(saxiclk) reset_by(saxireset);
      method esaxi_rvalid rvalid() clocked_by(saxiclk) reset_by(saxireset);
      method wdata(esaxi_wdata) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_wdata);
      method wid(esaxi_wid) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_wid);
      method wlast(esaxi_wlast) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_wlast);
      method esaxi_wready wready() clocked_by(saxiclk) reset_by(saxireset);
      method wstrb(esaxi_wstrb) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_wstrb);
      method wvalid(esaxi_wvalid) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_esaxi_wvalid);
      method esaxi_rid rid() clocked_by(saxiclk) reset_by(saxireset);
      //interface extraType   extra;
            
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
   maxi.aresetn, csysreq, rxi.data_p, rxi.data_n, rxi.frame_p,
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
   maxi.aresetn, csysreq, rxi.data_p, rxi.data_n, rxi.frame_p,
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
