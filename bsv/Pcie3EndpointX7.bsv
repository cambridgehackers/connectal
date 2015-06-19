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

interface PcieEndpointX7#(numeric type lanes);
   interface PciewrapPci_exp#(lanes)           pcie;
   interface PciewrapUser#(lanes)              user;
   interface PciewrapPipe#(lanes)              pipe;
   interface PciewrapCommon#(lanes)            common;
   interface Server#(TLPData#(16), TLPData#(16)) tlp;
   interface Clock epClock125;
   interface Reset epReset125;
   interface Clock epClock250;
   interface Reset epReset250;
   interface Clock epPcieClock;
   interface Reset epPcieReset;
   interface Clock epPortalClock;
   interface Reset epPortalReset;
   interface Clock epDerivedClock;
   interface Reset epDerivedReset;
endinterface

typedef struct {
   Bit#(85)      user;
   Bit#(1)       last;
   Bit#(8)       keep;
   Bit#(256)     data;
} AxiCQ deriving (Bits, Eq);

typedef struct {
   Bit#(75)      user;
   Bit#(1)       last;
   Bit#(8)       keep;
   Bit#(256)     data;
} AxiRC deriving (Bits, Eq);

typedef struct {
   Bit#(1)       last;
   Bit#(8)       keep;
   Bit#(256)     data;
   Bit#(33)      user;
   Bit#(1)       valid;
} AxiCC deriving (Bits, Eq);

typedef struct {
   Bit#(60)      user;
   Bit#(1)       last;
   Bit#(8)       keep;
   Bit#(256)     data;
   Bit#(1)       valid;
} AxiRQ deriving (Bits, Eq);

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
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
   Reset defaultResetInverted <- mkResetInverter(defaultReset, clocked_by defaultClock);

   PcieWrap#(PcieLanes) pcie_ep <- mkPcieWrap(defaultClock, defaultResetInverted);

   FIFOF#(AxiRC) fAxiRC <- mkBypassFIFOF(clocked_by pcie_ep.user_clk, reset_by noReset);
   FIFOF#(AxiCQ) fAxiCQ <- mkBypassFIFOF(clocked_by pcie_ep.user_clk, reset_by noReset);
   FIFOF#(AxiRQ) fAxiRQ <- mkBypassFIFOF(clocked_by pcie_ep.user_clk, reset_by noReset);
   FIFOF#(AxiCC) fAxiCC <- mkBypassFIFOF(clocked_by pcie_ep.user_clk, reset_by noReset);
   (* fire_when_enabled, no_implicit_conditions *)
   rule every1;
      Maybe#(Bit#(22)) rc_tready = Invalid;
      Maybe#(Bit#(22)) cq_tready = Invalid;
      if (fAxiRC.notFull) rc_tready = tagged Valid 22'h3FFFFF;
      if (fAxiCQ.notFull) cq_tready = tagged Valid 22'h3FFFFF;
      pcie_ep.m_axis_rc.tready(fromMaybe(0, rc_tready));
      pcie_ep.m_axis_cq.tready(fromMaybe(0, cq_tready));
   endrule

   // Drive s_axis_rq
   let rq_txready = (pcie_ep.s_axis_rq.tready != 0 && fAxiRQ.notEmpty);

   //(* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_rq if (rq_txready);
      let info = fAxiRQ.first; fAxiRQ.deq;
      pcie_ep.s_axis_rq.tvalid(1);
      pcie_ep.s_axis_rq.tlast(info.last);
      pcie_ep.s_axis_rq.tdata(info.data);
      pcie_ep.s_axis_rq.tkeep(info.keep);
      pcie_ep.s_axis_rq.tuser(info.user);
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_rq2 if (!rq_txready);
      pcie_ep.s_axis_rq.tvalid(0);
      pcie_ep.s_axis_rq.tlast(0);
      pcie_ep.s_axis_rq.tdata(0);
      pcie_ep.s_axis_rq.tkeep(0);
      pcie_ep.s_axis_rq.tuser(0);
   endrule

   // Drive s_axis_cc
   let cc_txready = (pcie_ep.s_axis_cc.tready != 0 && fAxiCC.notEmpty);

   //(* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_cc if (cc_txready);
      let info = fAxiCC.first; fAxiCC.deq;
      pcie_ep.s_axis_cc.tvalid(1);
      pcie_ep.s_axis_cc.tlast(info.last);
      pcie_ep.s_axis_cc.tdata(info.data);
      pcie_ep.s_axis_cc.tkeep(info.keep);
      pcie_ep.s_axis_cc.tuser(info.user);
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_cc2 if (!cc_txready);
      pcie_ep.s_axis_cc.tvalid(0);
      pcie_ep.s_axis_cc.tlast(0);
      pcie_ep.s_axis_cc.tdata(0);
      pcie_ep.s_axis_cc.tkeep(0);
      pcie_ep.s_axis_cc.tuser(0);
   endrule

   // Drive m_axis_rc
   (* fire_when_enabled *)
   rule sink_axi_rc if (pcie_ep.m_axis_rc.tvalid != 0);
      fAxiRC.enq(AxiRC {user: pcie_ep.m_axis_rc.tuser,
                        last: pcie_ep.m_axis_rc.tlast,
                        keep: pcie_ep.m_axis_rc.tkeep,
                        data: pcie_ep.m_axis_rc.tdata });
   endrule

   // Drive m_axis_cq
   (* fire_when_enabled *)
   rule sink_axi_cq if (pcie_ep.m_axis_cq.tvalid != 0);
      fAxiCQ.enq(AxiCQ {user: pcie_ep.m_axis_cq.tuser,
                        last: pcie_ep.m_axis_cq.tlast,
                        keep: pcie_ep.m_axis_cq.tkeep,
                        data: pcie_ep.m_axis_cq.tdata });
   endrule

   // The PCIe endpoint exports full (250MHz) and half-speed (125MHz) clocks
   Clock clock250 = pcie_ep.user_clk;
   Reset user_reset_n <- mkResetInverter(pcie_ep.user_reset, clocked_by clock250);
   Reset reset250 <- mkAsyncReset(4, pcie_ep.user_reset, clock250);
   Reset reset250_n <- mkAsyncReset(4, user_reset_n, clock250);

   ClockGenerator7Params     clkgenParams = defaultValue;
   clkgenParams.clkin1_period    = 4.000; //  250MHz
   clkgenParams.clkin1_period    = 4.000;
   clkgenParams.clkin_buffer     = False;
   clkgenParams.clkfbout_mult_f  = 4.000; // 1000MHz
   clkgenParams.clkout0_divide_f = 8.000; //  125MHz
   clkgenParams.clkout1_divide     = round(derivedClockPeriod);
   clkgenParams.clkout1_duty_cycle = 0.5;
   clkgenParams.clkout1_phase      = 0.0000;
   ClockGenerator7           clkgen <- mkClockGenerator7(clkgenParams, clocked_by clock250, reset_by reset250);
   Clock clock125 = clkgen.clkout0; /* half speed user_clk */
   Reset reset125 <- mkAsyncReset(4, reset250, clock125);
   Clock derivedClock = clkgen.clkout1;
   Reset derivedReset <- mkAsyncReset(4, reset250, derivedClock);
//
//   Server#(TLPData#(8), TLPData#(8)) tlp8 = (interface Server;
//						interface Put request;
//						   method Action put(TLPData#(8) data);
//						      fAxiTx.enq(AxiTx {last: pack(data.eof),
//									keep: dwordSwap64BE(data.be), data: dwordSwap64(data.data) });
//						   endmethod
//						endinterface
//						interface Get response;
//						   method ActionValue#(TLPData#(8)) get();
//						      let info <- toGet(fAxiRx).get;
//						      TLPData#(8) retval = defaultValue;
//						      retval.sof  = (info.user[14] == 1);
//						      retval.eof  = info.last != 0;
//						      retval.hit  = info.user[8:2];
//						      retval.be= dwordSwap64BE(info.keep);
//						      retval.data = dwordSwap64(info.data);
//						      return retval;
//						   endmethod
//						endinterface
//					     endinterface);

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
//   mkConnection(tlp8, gb.tlp, clocked_by portalClock, reset_by portalReset);

   interface tlp = gb.pci;
   interface pcie    = pcie_ep.pci_exp;
   interface Pcie3wrapUser user = pcie_ep.user;
   interface PciewrapPipe pipe = pcie_ep.pipe;
   interface PciewrapCommon common= pcie_ep.common;
   interface Clock epClock125 = clock125;
   interface Reset epReset125 = reset125;
   interface Clock epClock250 = clock250;
   interface Reset epReset250 = reset250;
   interface Clock epPcieClock = clock125;
   interface Reset epPcieReset = reset125;
   interface Clock epPortalClock = portalClock;
   interface Reset epPortalReset = portalReset;
   interface Clock epDerivedClock = derivedClock;
   interface Reset epDerivedReset = derivedReset;
endmodule: mkPcieEndpointX7

endpackage: Pcie3EndpointX7
