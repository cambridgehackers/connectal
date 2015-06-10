// Copyright (c) 2014-2015 Quanta Research Cambridge, Inc.

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

package Pcie3EndpointX7;

import Clocks            ::*;
import Vector            ::*;
import Connectable       ::*;
import GetPut            ::*;
import Reserved          ::*;
import TieOff            ::*;
import DefaultValue      ::*;
import DReg              ::*;
import Gearbox           ::*;
import FIFO              ::*;
import FIFOF             ::*;
import SpecialFIFOs      ::*;
import ClientServer      ::*;
import Real              ::*;

import ConnectalClocks   ::*;
import ConnectalXilinxCells   ::*;
import XilinxCells       ::*;
import PCIE              ::*;
import PCIEWRAPPER3      ::*;
import Bufgctrl           ::*;
import PcieGearbox       :: *;

(* always_ready, always_enabled *)
interface PCIE_X7#(numeric type lanes);
   interface PciewrapPci_exp#(lanes)   pcie;
   interface PciewrapUser#(lanes)      user;
   interface PciewrapFc#(lanes)        fc;
   interface PciewrapTx#(lanes)        tx;
   interface PciewrapS_axis_tx#(lanes) s_axis_tx;
   interface PciewrapM_axis_rx#(lanes) m_axis_rx;
   interface PciewrapRx#(lanes)        rx;
   interface PciewrapCfg#(lanes)       cfg;
   method    Action                    cfg_dsn(Bit#(64) i);
   interface Clock                     pipe_txoutclk_out;
   method    Action                    pipe_mmcm_lock_in(Bit#(1) v);
   method    Bit#(lanes)               pipe_pclk_sel_out();
endinterface

interface PcieEndpointX7#(numeric type lanes);
   interface PciewrapPci_exp#(lanes)   pcie;
   interface PciewrapUser#(lanes)      user;
   interface PciewrapCfg#(lanes)       cfg;
   interface Server#(TLPData#(16), TLPData#(16)) tlp;
   interface Clock epClock125;
   interface Reset epReset125;
   interface Clock epClock250;
   interface Reset epReset250;
   interface Clock epDerivedClock;
   interface Reset epDerivedReset;
endinterface

typedef struct {
   Bit#(22)      user;
   Bit#(1)       last;
   Bit#(8)       keep;
   Bit#(64)      data;
} AxiRx deriving (Bits, Eq);

typedef struct {
   Bit#(1)       last;
   Bit#(8)       keep;
   Bit#(64)      data;
} AxiTx deriving (Bits, Eq);

`ifdef BOARD_vc709
typedef 8 PcieLanes;
typedef 8 NumLeds;
`endif
`ifdef BOARD_nfsume
typedef 8 PcieLanes;
typedef 2 NumLeds;
`endif

(* synthesize *)
module mkPcieEndpointX7(PcieEndpointX7#(PcieLanes));

   PCIEParams params = defaultValue;

   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   B2C1 b2c <- mkB2C1();
   ClockGenerator7AdvParams   clockParams = defaultValue;
   clockParams.bandwidth          = "OPTIMIZED";
   clockParams.compensation       = "INTERNAL";
   clockParams.clkfbout_mult_f    = 10.000;
   clockParams.clkfbout_phase     = 0.0;
   clockParams.clkin1_period      = 10.000;
   clockParams.clkout0_divide_f   = 8.000;
   clockParams.clkout0_duty_cycle = 0.5;
   clockParams.clkout0_phase      = 0.0000;
   clockParams.clkout1_divide     = 4;
   clockParams.clkout1_duty_cycle = 0.5;
   clockParams.clkout1_phase      = 0.0000;
   clockParams.clkout2_divide     = 4;
   clockParams.clkout2_duty_cycle = 0.5;
   clockParams.clkout2_phase      = 0.0000;
   clockParams.divclk_divide      = 1;
   clockParams.ref_jitter1        = 0.010;
   clockParams.clkin_buffer = False;
   XClockGenerator7   clockGen <- mkClockGenerator7Adv(clockParams, clocked_by b2c.c);
   C2B c2b_fb <- mkC2B(clockGen.clkfbout, clocked_by clockGen.clkfbout);
   rule txoutrule5;
      clockGen.clkfbin(c2b_fb.o());
   endrule

   Reset defaultReset <- exposeCurrentReset();
   Bufgctrl bbufc <- mkBufgctrl(clockGen.clkout0, defaultReset, clockGen.clkout1, defaultReset);
   Reset rsto <- mkAsyncReset(2, defaultReset, bbufc.o);
   Reg#(Bit#(1)) pclk_sel <- mkReg(0, clocked_by bbufc.o, reset_by rsto);
   Reg#(Bit#(PcieLanes)) pclk_sel_reg1 <- mkReg(0, clocked_by bbufc.o, reset_by rsto);
   Reg#(Bit#(PcieLanes)) pclk_sel_reg2 <- mkReg(0, clocked_by bbufc.o, reset_by rsto);

   rule bufcruleinit;
      bbufc.ce0(1);
      bbufc.ce1(1);
      bbufc.ignore0(0);
      bbufc.ignore1(0);
   endrule
   rule bufcrule;
      bbufc.s0(~pclk_sel);
      bbufc.s1(pclk_sel);
   endrule

   PCIE_X7#(PcieLanes) pcie_ep <- vMkXilinx7PCIExpress(params, clockGen.clkout0, clockGen.clkout2, bbufc.o);
   //new PcieWrap#(PcieLanes)  pciew <- mkPcieWrap();

   FIFOF#(AxiTx)             fAxiTx              <- mkBypassFIFOF(clocked_by pcie_ep.user.clk_out, reset_by noReset);
   FIFOF#(AxiRx)             fAxiRx              <- mkBypassFIFOF(clocked_by pcie_ep.user.clk_out, reset_by noReset);

   (* fire_when_enabled, no_implicit_conditions *)
   rule every1;
      pcie_ep.fc.sel(0 /*RECEIVE_BUFFER_AVAILABLE_SPACE*/);
      pcie_ep.cfg_dsn({ 32'h0000_0001, {{ 8'h1 } , 24'h000A35 }});
      pcie_ep.rx.np_ok(1);
      pcie_ep.rx.np_req(1);
      pcie_ep.tx.cfg_gnt(1);
      pcie_ep.s_axis_tx.tuser(4'b0);
      pcie_ep.m_axis_rx.tready(pack(fAxiRx.notFull));
   endrule
   rule every2;
      pcie_ep.pipe_mmcm_lock_in(pack(clockGen.locked));
   endrule
   rule every3;
      pclk_sel_reg1 <= pcie_ep.pipe_pclk_sel_out();
   endrule

   Clock txoutclk_buf <- mkClockBUFG(clocked_by pcie_ep.pipe_txoutclk_out);

   C2B c2b <- mkC2B(txoutclk_buf);
   rule txoutrule;
      b2c.inputclock(c2b.o());
   endrule

   rule update_psel;
       let ps = pclk_sel;
       pclk_sel_reg2 <= pclk_sel_reg1;
       if ((~pclk_sel_reg2) == 0)
           ps = 1;
       else if (pclk_sel_reg2 == 0)
           ps = 0;
       pclk_sel <= ps;
   endrule

   let txready = (pcie_ep.s_axis_tx.tready != 0 && fAxiTx.notEmpty);

   //(* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_tx if (txready);
      let info = fAxiTx.first; fAxiTx.deq;
      pcie_ep.s_axis_tx.tvalid(1);
      pcie_ep.s_axis_tx.tlast(info.last);
      pcie_ep.s_axis_tx.tdata(info.data);
      pcie_ep.s_axis_tx.tkeep(info.keep);
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_tx2 if (!txready);
      pcie_ep.s_axis_tx.tvalid(0);
      pcie_ep.s_axis_tx.tlast(0);
      pcie_ep.s_axis_tx.tdata(0);
      pcie_ep.s_axis_tx.tkeep(0);
   endrule

   (* fire_when_enabled *)
   rule sink_axi_rx if (pcie_ep.m_axis_rx.tvalid != 0);
      fAxiRx.enq(AxiRx {user: pcie_ep.m_axis_rx.tuser,
                        last: pcie_ep.m_axis_rx.tlast,
                        keep: pcie_ep.m_axis_rx.tkeep,
                        data: pcie_ep.m_axis_rx.tdata });
   endrule

   // The PCIe endpoint exports full (250MHz) and half-speed (125MHz) clocks
   Clock clock250 = pcie_ep.user.clk_out;
   Reset user_reset_n <- mkResetInverter(pcie_ep.user.reset_out, clocked_by clock250);
   Reset reset250 <- mkAsyncReset(4, user_reset_n, clock250);

   ClockGenerator7Params     clkgenParams = defaultValue;
   clkgenParams.clkin1_period    = 4.000; //  250MHz
   clkgenParams.clkin1_period    = 4.000;
   clkgenParams.clkin_buffer     = False;
   clkgenParams.clkfbout_mult_f  = 4.000; // 1000MHz
   clkgenParams.clkout0_divide_f = 8.000; //  125MHz
   clkgenParams.clkout1_divide     = round(derivedClockPeriod);
   clkgenParams.clkout1_duty_cycle = 0.5;
   clkgenParams.clkout1_phase      = 0.0000;
   ClockGenerator7           clkgen <- mkClockGenerator7(clkgenParams, clocked_by clock250, reset_by user_reset_n);
   Clock clock125 = clkgen.clkout0; /* half speed user_clk */
   Reset reset125 <- mkAsyncReset(4, user_reset_n, clock125);
   Clock derivedClock = clkgen.clkout1;
   Reset derivedReset <- mkAsyncReset(4, user_reset_n, derivedClock);

   Server#(TLPData#(8), TLPData#(8)) tlp8 = (interface Server;
						interface Put request;
						   method Action put(TLPData#(8) data);
						      fAxiTx.enq(AxiTx {last: pack(data.eof),
									keep: dwordSwap64BE(data.be), data: dwordSwap64(data.data) });
						   endmethod
						endinterface
						interface Get response;
						   method ActionValue#(TLPData#(8)) get();
						      let info <- toGet(fAxiRx).get;
						      TLPData#(8) retval = defaultValue;
						      retval.sof  = (info.user[14] == 1);
						      retval.eof  = info.last != 0;
						      retval.hit  = info.user[8:2];
						      retval.be= dwordSwap64BE(info.keep);
						      retval.data = dwordSwap64(info.data);
						      return retval;
						   endmethod
						endinterface
					     endinterface);

`ifdef PCIE_250MHZ
   Clock portalClock = clock250;
   Reset portalReset = reset250;
`else
   Clock portalClock = clock125;
   Reset portalReset = reset125;
`endif
   // The PCIE endpoint is processing TLPData#(8)s at 250MHz.  The
   // AXI bridge is accepting TLPData#(16)s at 125 MHz. The
   // connection between the endpoint and the AXI contains GearBox
   // instances for the TLPData#(8)@250 <--> TLPData#(16)@125
   // conversion.
   PcieGearbox gb <- mkPcieGearbox(clock250, reset250, portalClock, portalReset);
   mkConnection(tlp8, gb.tlp, clocked_by portalClock, reset_by portalReset);

   interface tlp = gb.pci;
   interface pcie    = pcie_ep.pcie;
   interface PciewrapUser user = pcie_ep.user;
   interface PciewrapCfg cfg = pcie_ep.cfg;
   interface Clock epClock125 = clock125;
   interface Reset epReset125 = reset125;
   interface Clock epClock250 = clock250;
   interface Reset epReset250 = reset250;
   interface Clock epDerivedClock = derivedClock;
   interface Reset epDerivedReset = derivedReset;
endmodule: mkPcieEndpointX7

endpackage: Pcie3EndpointX7
