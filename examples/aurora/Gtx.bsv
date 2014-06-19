
// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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

import Vector::*;
import GetPut::*;
import ClientServer::*;
import Clocks::*;

interface Drp#(numeric type asz, numeric type dsz);
   method Action addr(Bit#(asz) a);
   method Action en(Bit#(1) en);
   method Action we(Bit#(1) we);
   method Bit#(dsz) dout();
   method Action din(Bit#(dsz) d);
   method Bit#(1) rdy();
endinterface

interface Gtxe2Qpll;
   method Action reset(Bool v);
   method Bit#(1) lock();
   interface Clock outClk;
   interface Clock outRefClk;
   method Bit#(1) refClkLost();
endinterface

interface VGtxe2Common;
    (* always_ready, always_enabled *)
   interface Gtxe2Qpll qpll;
    (* always_ready, always_enabled *)
   interface Drp#(9,16) drp;
endinterface

import "BVI" GTXE2_COMMON =
module vMkGtxe2Common#(Clock qpllLockDetClk, Clock gtrefclk0, Clock drpClk)(VGtxe2Common);

   default_clock clk();
   default_reset reset();
   input_clock gtrefclk0(GTREFCLK0) = gtrefclk0;
   input_clock qpllLockDetClk(QPLLLOCKDETCLK) = qpllLockDetClk;
   input_clock drpClk(DRPCLK) = drpClk;

   parameter BIAS_CFG                               = (64'h0000040000001000);
   parameter COMMON_CFG                             = (32'h00000000);
   parameter QPLL_CFG                               = (27'h06801C1);
   parameter QPLL_CLKOUT_CFG                        = (4'b0000);
   parameter QPLL_COARSE_FREQ_OVRD                  = (6'b010000);
   parameter QPLL_COARSE_FREQ_OVRD_EN               = (1'b0);
   parameter QPLL_CP                                = (10'b0000011111);
   parameter QPLL_CP_MONITOR_EN                     = (1'b0);
   parameter QPLL_DMONITOR_SEL                      = (1'b0);
   parameter QPLL_FBDIV                             = (10'b0000100000);
   parameter QPLL_FBDIV_MONITOR_EN                  = (1'b0);
   parameter QPLL_FBDIV_RATIO                       = (1'b1);
   parameter QPLL_INIT_CFG                          = (24'h000006);
   parameter QPLL_LOCK_CFG                          = (16'h21E8);
   parameter QPLL_LPF                               = (4'b1111);
   parameter QPLL_REFCLK_DIV                        = (1);

   port GTGREFCLK = 0;
   port GTNORTHREFCLK0 = 0;
   port GTNORTHREFCLK1 = 0;
   //port GTREFCLK0 = gtrefclk0;
   port GTREFCLK1 = 0;
   port GTSOUTHREFCLK0 = 0;
   port GTSOUTHREFCLK1 = 0;
   port QPLLLOCKEN = 1;
   port QPLLOUTRESET = 0;
   port QPLLPD = 0;
   port QPLLREFCLKSEL = 3'b1;
   port QPLLRSVD1 = 0;
   port QPLLRSVD2 = 5'b11111;
   port RCALENB = 1;
   port BGBYPASSB = 1;
   port BGMONITORENB = 1;
   port BGPDB = 1;
   port BGRCALOVRD = 5'b11111;
   port PMARSVD = 0;
   interface Drp drp;
      method din(DRPDI) enable((*inhigh*)EN_DI) clocked_by(drpClk);
      method addr(DRPADDR) enable((*inhigh*)EN_ADDR) clocked_by(drpClk);
      method en(DRPEN) enable((*inhigh*)EN_EN) clocked_by(drpClk);
      method we(DRPWE) enable((*inhigh*)EN_WE) clocked_by(drpClk);
      method DRPDO dout() clocked_by(drpClk);
      method DRPRDY rdy() clocked_by(drpClk);
   endinterface
   interface Gtxe2Qpll qpll;
      method reset(QPLLRESET) enable ((*inhigh*)EN_RESET);
      method QPLLLOCK lock();
      output_clock outClk(QPLLOUTCLK);
      output_clock outRefClk(QPLLOUTREFCLK);
      method QPLLREFCLKLOST refClkLost();
   endinterface
   schedule (qpll_reset, qpll_lock, qpll_refClkLost, drp_addr, drp_din, drp_en, drp_we, drp_dout, drp_rdy, drp_we)
         CF (qpll_reset, qpll_lock, qpll_refClkLost, drp_addr, drp_din, drp_en, drp_we, drp_dout, drp_rdy, drp_we);
endmodule: vMkGtxe2Common

typedef struct {
   Bool      isWrite;
   Bit#(asz) addr;
   Bit#(dsz) data;
   } DrpRequest#(numeric type asz, numeric type dsz) deriving (Bits,Eq);

interface Gtxe2Common;
   interface Gtxe2Qpll qpll;
   interface Server#(DrpRequest#(9,16),Bit#(16)) drp;
endinterface

(* synthesize *)
module mkGtxe2Common#(Clock qpllLockDetClk, Clock gtrefclk0, Clock drpClk)(Gtxe2Common);
   let m <- vMkGtxe2Common(qpllLockDetClk, gtrefclk0, drpClk);
   let defaultReset <- exposeCurrentReset();
   let drpReset <- mkAsyncReset(2, defaultReset, drpClk);
   Wire#(Bit#(1)) drpen <- mkDWire(0, clocked_by drpClk, reset_by drpReset);
   rule drpenrule;
      m.drp.en(drpen);
   endrule

   Reg#(Bool) resetWire <- mkReg(False);
   rule qpll_reset_rule;
      m.qpll.reset(resetWire);
   endrule

   interface Gtxe2Qpll qpll;
      method Action reset(Bool v);
	 resetWire <= v;
      endmethod
      method lock = m.qpll.lock;
      interface outClk = m.qpll.outClk;
      interface outRefClk = m.qpll.outRefClk;
      method refClkLost = m.qpll.refClkLost;
   endinterface
   interface Server drp;
      interface Put request;
	 method Action put(DrpRequest#(9,16) req);
	    m.drp.addr(req.addr);
	    m.drp.din(req.data);
	    m.drp.we(pack(req.isWrite));
	    drpen <= 1;
	 endmethod
      endinterface
      interface Get response;
	 method ActionValue#(Bit#(16)) get() if (unpack(m.drp.rdy()));
	    return m.drp.dout();
	 endmethod
      endinterface
   endinterface
endmodule
