// Copyright (c) 2012-2013 Nokia, Inc.
// Copyright (c) 2014-2015 Quanta Research Cambridge, Inc.
// Copyright (c) 2015 Connectal Project

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

package Pcie2EndpointX7;

import ConnectalConfig   ::*;
import BRAMFIFO          ::*;
import Clocks            ::*;
import Vector            ::*;
import BuildVector       ::*;
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
import PCIEWRAPPER2      ::*;
import Pipe              ::*;
import PcieStateChanges  ::*;
import Bufgctrl           ::*;


////////////////////////////////////////////////////////////////////////////////
/// Interfaces
////////////////////////////////////////////////////////////////////////////////

interface PcieEndpointX7#(numeric type lanes);
   interface PciewrapPci_exp#(lanes)   pcie;
   interface PciewrapUser#(lanes)      user;
   interface PciewrapCfg#(lanes)       cfg;
   interface Server#(TLPData#(16), TLPData#(16)) tlp;
   interface PipeOut#(Bit#(64)) regChanges;
   interface Clock epPcieClock;
   interface Reset epPcieReset;
   interface Clock epPortalClock;
   interface Reset epPortalReset;
   interface Clock epDerivedClock;
   interface Reset epDerivedReset;
endinterface

typedef struct {
   Bit#(22)      user;
   Bit#(1)       last;
   Bit#(16)      keep;
   Bit#(128)     data;
} AxiRx deriving (Bits, Eq);

typedef struct {
   Bit#(1)       last;
   Bit#(16)      keep;
   Bit#(128)     data;
} AxiTx deriving (Bits, Eq);

(* synthesize *)
module mkPcieEndpointX7(PcieEndpointX7#(PcieLanes));

   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

   PcieWrap#(PcieLanes) pcie_ep <- mkPcieWrap(defaultClock, defaultReset);

   Clock user_clk = pcie_ep.user_clk_out;
   Reset user_reset_n <- mkResetInverter(pcie_ep.user_reset_out, clocked_by user_clk);

   FIFOF#(AxiTx)             fAxiTx              <- mkFIFOF(clocked_by user_clk, reset_by user_reset_n);
   FIFOF#(AxiRx)             fAxiRx              <- mkFIFOF(clocked_by user_clk, reset_by user_reset_n);

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
   rule every_cfg_err;
      pcie_ep.cfg_err.acs(0);
      pcie_ep.cfg_err.aer_headerlog(0);
      pcie_ep.cfg_err.atomic_egress_blocked(0);
      pcie_ep.cfg_err.cor(0);
      pcie_ep.cfg_err.cpl_abort(0);
      pcie_ep.cfg_err.cpl_timeout(0);
      pcie_ep.cfg_err.cpl_unexpect(0);
      pcie_ep.cfg_err.ecrc(0);
      pcie_ep.cfg_err.internal_cor(0);
      pcie_ep.cfg_err.internal_uncor(0);
      pcie_ep.cfg_err.locked(0);
      pcie_ep.cfg_err.malformed(0);
      pcie_ep.cfg_err.mc_blocked(0);
      pcie_ep.cfg_err.norecovery(0);
      pcie_ep.cfg_err.poisoned(0);
      pcie_ep.cfg_err.posted(0);
      pcie_ep.cfg_err.tlp_cpl_header(0);
      pcie_ep.cfg_err.ur(0);
   endrule
   rule every_interrupt;
      pcie_ep.cfg_interrupt.zzassert(0);
      pcie_ep.cfg_interrupt.di(0);
      pcie_ep.cfg_interrupt.stat(0);
   endrule
   rule every_mgmt;
      pcie_ep.cfg_mgmt.byte_en(0);
      pcie_ep.cfg_mgmt.di(0);
      pcie_ep.cfg_mgmt.dwaddr(0);
      pcie_ep.cfg_mgmt.rd_en(0);
      pcie_ep.cfg_mgmt.wr_en(0);
      pcie_ep.cfg_mgmt.wr_readonly(0);
   endrule
   rule every_pm;
      pcie_ep.cfg_pm.force_state(0);
      pcie_ep.cfg_pm.force_state_en(0);
      pcie_ep.cfg_pm.halt_aspm_l0s(0);
      pcie_ep.cfg_pm.halt_aspm_l1(0);
      pcie_ep.cfg_pm.send_pme_to(0);
      pcie_ep.cfg_pm.wake(0);
   endrule
   rule every_pl;
      pcie_ep.pl.directed_link_auton(0);
      pcie_ep.pl.directed_link_change(0);
      pcie_ep.pl.directed_link_speed(0);
      pcie_ep.pl.directed_link_width(0);
      pcie_ep.pl.downstream_deemph_source(0);
      pcie_ep.pl.transmit_hot_rst(0);
      pcie_ep.pl.upstream_prefer_deemph(1);
   endrule

   Vector#(17,Tuple2#(PcieCfgType,Bit#(24))) changeValues = vec(
      //tuple2(PcieCfg_initial_link_width, extend(pcie_ep.pl.initial_link_width)),
      //tuple2(PcieCfg_lane_reversal_mode, extend(pcie_ep.pl.lane_reversal_mode)),
      tuple2(PcieCfg_ltssm_state, extend(pcie_ep.pl.ltssm_state)),
      tuple2(PcieCfg_phy_link_up, extend(pcie_ep.pl.phy_lnk_up)),
      tuple2(PcieCfg_received_hot_rst, extend(pcie_ep.pl.received_hot_rst)),
      //tuple2(PcieCfg_rx_pm_state, extend(pcie_ep.pl.rx_pm_state)),
      tuple2(PcieCfg_sel_lnk_rate, extend(pcie_ep.pl.sel_lnk_rate)),
      //tuple2(PcieCfg_negotiated_width, extend(pcie_ep.pl.sel_lnk_width)),
      //tuple2(PcieCfg_tx_pm_state, extend(pcie_ep.pl.tx_pm_state)),
      tuple2(PcieCfg_link_up, extend(pcie_ep.user.lnk_up)),
      tuple2(PcieCfg_link_gen2_cap, extend(pcie_ep.pl_link_gen2_cap)),
      tuple2(PcieCfg_link_partner_gen2_supported, extend(pcie_ep.pl_link_partner_gen2_supported)),
      tuple2(unpack(50), extend(pcie_ep.cfg.pcie_link_state)),
      tuple2(unpack(51), extend(pcie_ep.cfg_aer.rooterr_corr_err_received)),
      tuple2(unpack(52), extend(pcie_ep.cfg_aer.rooterr_fatal_err_received)),
      tuple2(unpack(53), extend(pcie_ep.cfg_msg.received)),
      tuple2(unpack(54), extend(pcie_ep.cfg_msg.received_err_cor)),
      tuple2(unpack(55), extend(pcie_ep.cfg_msg.received_err_fatal)),
      tuple2(unpack(56), extend(pcie_ep.cfg_msg.received_err_non_fatal)),
      tuple2(unpack(57), extend(pcie_ep.cfg_pmcsr.pme_en)),
      tuple2(unpack(58), extend(pcie_ep.cfg_pmcsr.pme_status)),
      tuple2(unpack(59), extend(pcie_ep.cfg_pmcsr.powerstate)));

   Reg#(Bit#(32)) cyclesReg <- mkReg(0, clocked_by user_clk, reset_by user_reset_n);
   rule rl_cycles;
      cyclesReg <= cyclesReg + 1;
   endrule
   let change_pipes <- mapM(mkChangeSource(cyclesReg), changeValues, clocked_by user_clk, reset_by user_reset_n);

   FunnelPipe#(1,17,RegChange,3) changePipe <- mkFunnelPipesPipelined(change_pipes, clocked_by user_clk, reset_by user_reset_n);
   FIFOF#(RegChange) changeFifo <- mkSizedBRAMFIFOF(128, clocked_by user_clk, reset_by user_reset_n);
   mkConnection(changePipe[0], toPipeIn(changeFifo), clocked_by user_clk, reset_by user_reset_n);

   let txready = (pcie_ep.s_axis_tx.tready == 1 && fAxiTx.notEmpty);

   (* fire_when_enabled *)
   rule drive_axi_tx if (txready);
      let info = unpack(0);
      if (fAxiTx.notEmpty) begin
	 info <- toGet(fAxiTx).get();
      end
      pcie_ep.s_axis_tx.tlast(info.last);
      pcie_ep.s_axis_tx.tdata(info.data);
      pcie_ep.s_axis_tx.tkeep(info.keep);
   endrule
   (* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_txvalid if (fAxiTx.notEmpty);
      pcie_ep.s_axis_tx.tvalid(1);
   endrule
   (* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_tx2 if (!fAxiTx.notEmpty);
      pcie_ep.s_axis_tx.tvalid(0);
      pcie_ep.s_axis_tx.tlast(0);
      pcie_ep.s_axis_tx.tdata(0);
      pcie_ep.s_axis_tx.tkeep(0);
   endrule

   (* fire_when_enabled *)
   rule sink_axi_rx if (pcie_ep.m_axis_rx.tvalid == 1);
      fAxiRx.enq(AxiRx {user: pcie_ep.m_axis_rx.tuser,
                        last: pcie_ep.m_axis_rx.tlast,
                        keep: pcie_ep.m_axis_rx.tkeep,
                        data: pcie_ep.m_axis_rx.tdata });
   endrule

   ClockGenerator7Params     clkgenParams = defaultValue;
   clkgenParams.clkin1_period    = 4.000; //  250MHz
   clkgenParams.clkin_buffer     = False;
   clkgenParams.clkfbout_mult_f  = 4.000; // 1000MHz
   clkgenParams.clkout0_divide_f = derivedClockPeriod;
   clkgenParams.clkout1_divide     = round(mainClockPeriod);
   clkgenParams.clkout1_duty_cycle = 0.5;
   clkgenParams.clkout1_phase      = 0.0000;
   clkgenParams.clkout2_divide     = 4; // 250MHz
   clkgenParams.clkout2_duty_cycle = 0.5;
   clkgenParams.clkout2_phase      = 0.0000;
   ClockGenerator7           clkgen <- mkClockGenerator7(clkgenParams, clocked_by user_clk, reset_by user_reset_n);
   Clock portalClock;
   Reset portalReset;
   if (mainClockPeriod == pcieClockPeriod) begin
      portalClock = user_clk;
      portalReset = user_reset_n;
   end
   else begin
      portalClock = clkgen.clkout1;
      portalReset <- mkAsyncReset(4, user_reset_n, portalClock);
   end
   Clock derivedClock = clkgen.clkout0;
   Reset derivedReset <- mkAsyncReset(4, user_reset_n, derivedClock);

   Server#(TLPData#(16), TLPData#(16)) tlp16 = (interface Server;
						interface Put request;
						   method Action put(TLPData#(16) data);
						      fAxiTx.enq(AxiTx {last: pack(data.eof),
									keep: dwordSwap128BE(data.be), data: dwordSwap128(data.data) });
						   endmethod
						endinterface
						interface Get response;
						   method ActionValue#(TLPData#(16)) get();
						      let info <- toGet(fAxiRx).get;
						      TLPData#(16) retval = defaultValue;
						      retval.sof  = (info.user[14] == 1);
						      retval.eof  = (info.user[21] == 1); // 128-bit interface uses tuser bits instead of tlast to indicate EOF
						      retval.hit  = info.user[8:2];
						      retval.be= dwordSwap128BE(info.keep);
						      retval.data = dwordSwap128(info.data);
						      return retval;
						   endmethod
						endinterface
					     endinterface);

   interface tlp = tlp16;
   interface pcie    = pcie_ep.pci_exp;
   interface PciewrapUser user = pcie_ep.user;
   interface PciewrapCfg cfg = pcie_ep.cfg;
   interface regChanges = mapPipe(pack, toPipeOut(changeFifo));
   interface Clock epPcieClock = user_clk;
   interface Reset epPcieReset = user_reset_n;
   interface Clock epPortalClock = portalClock;
   interface Reset epPortalReset = portalReset;
   interface Clock epDerivedClock = derivedClock;
   interface Reset epDerivedReset = derivedReset;
endmodule: mkPcieEndpointX7

endpackage: Pcie2EndpointX7
