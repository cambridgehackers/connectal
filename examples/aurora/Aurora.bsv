
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

import FIFO::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import XbsvXilinxCells::*;
import XilinxCells::*;
import BviAurora::*;
import Clocks::*;
import FrequencyCounter::*;

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

(* always_enabled, always_ready *)
interface AuroraPins;
   method Action userClk(Bit#(1) p, Bit#(1) n);
   method Action mgtRefClk(Bit#(1) p, Bit#(1) n);
   method Action mgtRx(Bit#(1) p, Bit#(1) n);
   method Bit#(1) mgtTx_p();
   method Bit#(1) mgtTx_n();
   interface DiffClock smaUserClk;
endinterface

interface AuroraIndication;
    method Action received(Bit#(64) v);
    method Action debug(Bit#(1) channelUp, Bit#(1) laneUp, Bit#(1) hard_err, Bit#(1) soft_err, Bit#(1) qpllLock, Bit#(1) qpllRefClkLost);
    method Action userClkElapsedCycles(Bit#(32) cycles);
    method Action mgtRefClkElapsedCycles(Bit#(32) cycles);
    method Action outClkElapsedCycles(Bit#(32) cycles);
    method Action outRefClkElapsedCycles(Bit#(32) cycles);
    method Action drpResponse(Bit#(16) v);
endinterface

interface AuroraRequest;
    method Action send(Bit#(64) v);
    method Action debug();
    method Action pma_init(Bit#(1) v);
    method Action userClkElapsedCycles(Bit#(32) period);
    method Action mgtRefClkElapsedCycles(Bit#(32) period);
    method Action outClkElapsedCycles(Bit#(32) period);
    method Action outRefClkElapsedCycles(Bit#(32) period);
    method Action drpRequest(Bit#(9) addr, Bit#(16) data, Bit#(1) isWrite);
    method Action qpllReset(Bit#(1) v);
endinterface

interface Aurora;
   interface AuroraRequest request;
   interface AuroraPins pins;
endinterface

module mkAuroraRequest#(AuroraIndication indication)(Aurora);
   let defaultClock <- exposeCurrentClock;
   let defaultReset <- exposeCurrentReset;

   Wire#(Bit#(1)) userClkWireP <- mkDWire(0);
   Wire#(Bit#(1)) userClkWireN <- mkDWire(0);
   Clock userClkIn <- mkClockIBUFDS(userClkWireP, userClkWireN);
   Clock userClk <- mkClockBUFG(clocked_by userClkIn);

   DiffClock smaUserClockDS <- mkClockOBUFDS(clocked_by userClk);

   let userReset <- mkAsyncReset(16, defaultReset, userClk);
   let userClkFreqCounter <- mkFrequencyCounter(userClk, userReset);

   Wire#(Bit#(1)) mgtRefClkWireP <- mkDWire(0);
   Wire#(Bit#(1)) mgtRefClkWireN <- mkDWire(0);
   Clock mgtRefClk <- mkClockIBUFDS_GTE2(True, mgtRefClkWireP, mgtRefClkWireN);

   let mgtRefClkReset <- mkAsyncReset(16, defaultReset, mgtRefClk);
   let mgtRefClkFreqCounter <- mkFrequencyCounter(mgtRefClk, mgtRefClkReset);

   let b2c <- mkB2C();
   Clock txClock <- mkClockBUFG(clocked_by b2c.c);

   Clock syncClock = txClock; // should be doubled

   let common <- mkGtxe2Common(defaultClock, mgtRefClk, defaultClock);

   let outClk <- mkClockBUFG(common.qpll.outClk);
   let outClkReset <- mkAsyncReset(2, defaultReset, outClk);
   let outClkFreqCounter <- mkFrequencyCounter(outClk, outClkReset);

   let outRefClk <- mkClockBUFG(common.qpll.outRefClk);
   let outRefClkReset <- mkAsyncReset(2, defaultReset, outRefClk);
   let outRefClkFreqCounter <- mkFrequencyCounter(outRefClk, outRefClkReset);

   let initReset <- mkAsyncReset(128, defaultReset, userClk);
   let aur <- mkBviAurora64(/* init_clk */ defaultClock,
			    mgtRefClk,
			    /* sync_clk */ syncClock,
			    /* user_clk */ txClock,
			    /* init_clk_reset */ defaultReset,
			    /* refclk1_in_reset */ defaultReset,
			    /* reset */ defaultReset,
			    /* sync_clk_reset */ defaultReset,
			    /* user_clk_reset */ defaultReset);
      
   Reg#(Bit#(1)) pmaInitVal <- mkReg(0);
   Reg#(Bit#(15)) ccCounter <- mkReg(0);

   rule tx_out_clk_rule;
      b2c.inputclock(aur.tx.out_clk());
   endrule
   // gt_pll_lock

   rule settings;
      aur.loopback(1);
      aur.power.down(0);
      aur.pma.init(pmaInitVal);
   endrule
   rule qpll;
      //aur.gt_qpllclk_quad2_in(common.qpll.outClk());
      //aur.gt_qpllrefclk_quad2_in(common.qpll.outRefClk());
   endrule      

   rule receive if (unpack(aur.m_axi_rx.tvalid()));
      let v = 0;
      indication.received(aur.m_axi_rx.tdata());
   endrule

   // The CC block code should be sent atleast once for every 5000 clock cycles.
   rule doCC;
      let counter = ccCounter + 1;
      let doCC = 0;
      if (aur.channel.up() == 0)
	 counter = 0;
      if (counter > 4992)
	 doCC = 1;
      aur.do_.cc(doCC);
      if (counter > 5000)
	 counter = 0;
      ccCounter <= counter;
   endrule
   rule userclkfreqcounter_rule;
      let ec <- userClkFreqCounter.elapsedCycles();
      indication.userClkElapsedCycles(ec);
   endrule
   rule mgtrefclkfreqcounter_rule;
      let ec <- mgtRefClkFreqCounter.elapsedCycles();
      indication.mgtRefClkElapsedCycles(ec);
   endrule
   rule outclkfreqcounter_rule;
      let ec <- outClkFreqCounter.elapsedCycles();
      indication.outClkElapsedCycles(ec);
   endrule
   rule outrefclkfreqcounter_rule;
      let ec <- outRefClkFreqCounter.elapsedCycles();
      indication.outRefClkElapsedCycles(ec);
   endrule
   rule drpResponseRule;
      let v <- common.drp.response.get();
      indication.drpResponse(v);
   endrule
	 
   interface AuroraRequest request;
       method Action send(Bit#(64) v) if (unpack(aur.s_axi_tx.tready()));
	  aur.s_axi_tx.tdata(v);
	  aur.s_axi_tx.tkeep(-1);
	  aur.s_axi_tx.tlast(1);
	  aur.s_axi_tx.tvalid(1);
       endmethod
      method Action debug();
	 indication.debug(aur.channel.up(), aur.lane.up(), aur.hard.err(), aur.soft.err(), common.qpll.lock(), common.qpll.refClkLost());
      endmethod
      method Action pma_init(Bit#(1) v);
	 pmaInitVal <= v;
      endmethod
      method Action userClkElapsedCycles(Bit#(32) period);
	 userClkFreqCounter.start(period);
      endmethod
      method Action mgtRefClkElapsedCycles(Bit#(32) period);
	 mgtRefClkFreqCounter.start(period);
      endmethod
      method Action outClkElapsedCycles(Bit#(32) period);
	 outClkFreqCounter.start(period);
      endmethod
      method Action outRefClkElapsedCycles(Bit#(32) period);
	 outRefClkFreqCounter.start(period);
      endmethod
      method Action drpRequest(Bit#(9) addr, Bit#(16) data, Bit#(1) isWrite);
         common.drp.request.put(DrpRequest { addr: addr, data: data, isWrite: unpack(isWrite) });
      endmethod
      method Action qpllReset(Bit#(1) v);
         common.qpll.reset(unpack(v));
      endmethod
   endinterface
   interface AuroraPins pins;
       method Action userClk(Bit#(1) p, Bit#(1) n);
	  userClkWireP <= p;
	  userClkWireN <= n;
       endmethod
       method Action mgtRefClk(Bit#(1) p, Bit#(1) n);
	  mgtRefClkWireP <= p;
	  mgtRefClkWireN <= n;
       endmethod
       method Action mgtRx(Bit#(1) p, Bit#(1) n);
	  aur.rxp(p);
	  aur.rxn(n);
       endmethod
       method mgtTx_p = aur.txp;
       method mgtTx_n = aur.txn;

       interface DiffClock smaUserClk = smaUserClockDS;
   endinterface

endmodule