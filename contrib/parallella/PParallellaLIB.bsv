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
   method Action wr_wait_p(Bit#(1) v);
   method Action wr_wait_n(Bit#(1) v);
   method Action rd_wait_p(Bit#(1) v);
   method Action rd_wait_n(Bit#(1) v);
   method Action cclk_p(Bit#(1));
   method Action cclk_n(Bit#(1));
endinterface

//

module mkPParallellaLIB#(Clock maxiclk, Clock saxiclk, 
   Reset maxiclk_reset, Reset saxiclk_reset,\
   Reset maxireset, Reset saxireset,
   Reset reset_chip, Reset reset_fpga)(PParallellaLib);
   default_clock clk();
   default_reset rst();
   input_clock axiclk(AXICLK) = axiclk;
   input_reset axiclk_reset() = axiclk_reset; /* from clock*/
   
   interface Par_txo;
      method data_p(txo_data_p) enable((*inhigh*) EN_txo_data_p);
      method data_n(txo_data_n) enable((*inhigh*) EN_txo_data_n);
      method frame_p(txo_frame_p) enable((*inhigh*) EN_txo_frame_p);
      method frame_n(txo_frame_n) enable((*inhigh*) EN_txo_frame_n);
      method txo_wr_wait_p wr_wait_p();
      method txo_wr_wait_n wr_wait_n();
      method txo_rd_wait_p rd_wait_p();
      method txo_rd_wait_n rd_wait_n();
   endinterface

   interface Par_rxi;
      method rxi_data_p data_p();
      method rxi_data_n data_n();
      method rxi_frame_p frame_p();
      method rxi_frame_n frame_n();
      method wr_wait_p(rxi_wr_wait_p) enable((*inhigh*) EN_rxi_wr_wait_p);
      method wr_wait_n(rxi_wr_wait_n) enable((*inhigh*) EN_rxi_wr_wait_n);
      method rd_wait_p(rxi_rd_wait_p) enable((*inhigh*) EN_rxi_rd_wait_p);
      method rd_wait_n(rxi_rd_wait_n) enable((*inhigh*) EN_rxi_rd_wait_n);
      method cclk_p(rxi_cclk_p) enable((*inhigh*) EN_rxi_cclk_p);
      method cclk_n(rxi_cclk_n) enable((*inhigh*) EN_rxi_cclk_p);
   endinterface
   
   interface Par_emaxi;
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
   
   
   
   
   interface Par_saxi;
      method araddr(saxi_araddr) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_araddr);
      method arburst(saxi_arburst) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_arburst);
      method arcache(saxi_arcache) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_arcache);
      method saxi_aresetn aresetn() clocked_by(saxiclk) reset_by(saxireset);
      method arid(saxi_arid) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_arid);
      method arlen(saxi_arlen) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_arlen);
      method arlock(saxi_arlock) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_arlock);
      method arprot(saxi_arprot) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_arprot);
      method arqos(saxi_arqos) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_arqos);
      method saxi_arready arready() clocked_by(saxiclk) reset_by(saxireset);
      method arsize(saxi_arsize) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_arsize);
      method arvalid(saxi_arvalid) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_arvalid);
      method awaddr(saxi_awaddr) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_awaddr);
      method awburst(saxi_awburst) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_awburst);
      method awcache(saxi_awcache) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_awcache);
      method awid(saxi_awid) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_awid);
      method awlen(saxi_awlen) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_awlen);
      method awlock(saxi_awlock) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_awlock);
      method awprot(saxi_awprot) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_awprot);
      method awqos(saxi_awqos) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_awqos);
      method saxi_awready awready() clocked_by(saxiclk) reset_by(saxireset);
      method awsize(saxi_awsize) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_awsize);
      method awvalid(saxi_awvalid) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_awvalid);
      method saxi_bid bid() clocked_by(saxiclk) reset_by(saxireset);
      method bready(saxi_bready) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_bready);
      method saxi_bresp bresp() clocked_by(saxiclk) reset_by(saxireset);
      method saxi_bvalid bvalid() clocked_by(saxiclk) reset_by(saxireset);
      method saxi_rdata rdata() clocked_by(saxiclk) reset_by(saxireset);
      method saxi_rlast rlast() clocked_by(saxiclk) reset_by(saxireset);
      method rready(saxi_rready) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_rready);
      method saxi_rresp rresp() clocked_by(saxiclk) reset_by(saxireset);
      method saxi_rvalid rvalid() clocked_by(saxiclk) reset_by(saxireset);
      method wdata(saxi_wdata) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_wdata);
      method wid(saxi_wid) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_wid);
      method wlast(saxi_wlast) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_wlast);
      method saxi_wready wready() clocked_by(saxiclk) reset_by(saxireset);
      method wstrb(saxi_wstrb) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_wstrb);
      method wvalid(saxi_wvalid) clocked_by(saxiclk) reset_by(saxireset) enable((*inhigh*) EN_saxi_wvalid);
      method saxi_rid rid() clocked_by(saxiclk) reset_by(saxireset);
      interface extraType   extra;
   endinterface
   
   
schedule (
   csysack, cactive, reset_chip, reset_fpga, txo_data_p, txo_data_n,
   txo_frame_p, txo_frame_n, txo_lclk_p, txo_lclk_n, rxo_wr_wait_p,
   rxo_wr_wait_n, rxo_rd_wait_p, rxo_rd_wait_n, rxi_cclk_p,
   rxi_cclk_n, emaxi_awid, emaxi_awaddr, emaxi_awlen, emaxi_awsize,
   emaxi_awburst, emaxi_awlock, emaxi_awcache, emaxi_awprot,
   emaxi_awvalid, esaxi_awready, emaxi_wid, emaxi_wdata, emaxi_wstrb,
   emaxi_wlast, emaxi_wvalid, esaxi_wready, emaxi_bready, esaxi_bid,
   esaxi_bresp, esaxi_bvalid, emaxi_arid, emaxi_araddr, emaxi_arlen,
   emaxi_arsize, emaxi_arburst, emaxi_arlock, emaxi_arcache,
   emaxi_arprot, emaxi_arvalid, esaxi_arready, emaxi_rready,
   esaxi_rid, esaxi_rdata, esaxi_rresp, esaxi_rlast, esaxi_rvalid,
   emaxi_awqos, emaxi_arqos,
   // Inputs
   clkin_100, esaxi_aclk, emaxi_aclk, reset, esaxi_aresetn,
   emaxi_aresetn, csysreq, rxi_data_p, rxi_data_n, rxi_frame_p,
   rxi_frame_n, rxi_lclk_p, rxi_lclk_n, txi_wr_wait_p, txi_wr_wait_n,
   txi_rd_wait_p, txi_rd_wait_n, emaxi_awready, esaxi_awid,
   esaxi_awaddr, esaxi_awlen, esaxi_awsize, esaxi_awburst,
   esaxi_awlock, esaxi_awcache, esaxi_awprot, esaxi_awvalid,
   emaxi_wready, esaxi_wid, esaxi_wdata, esaxi_wstrb, esaxi_wlast,
   esaxi_wvalid, emaxi_bid, emaxi_bresp, emaxi_bvalid, esaxi_bready,
   emaxi_arready, esaxi_arid, esaxi_araddr, esaxi_arlen, esaxi_arsize,
   esaxi_arburst, esaxi_arlock, esaxi_arcache, esaxi_arprot,
   esaxi_arvalid, emaxi_rid, emaxi_rdata, emaxi_rresp, emaxi_rlast,
   emaxi_rvalid, esaxi_rready, esaxi_awqos, esaxi_arqos
);

endmodule