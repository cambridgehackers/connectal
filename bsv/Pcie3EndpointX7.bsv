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
import XilinxVirtex7PCIE ::*;
import BUtils            ::*;

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
   interface Server#(TLPData#(16), TLPData#(16)) tlpr;
   interface Server#(TLPData#(16), TLPData#(16)) tlpc;
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
   Bit #(256)    data;
   Bool          sop;
   Bool          eop;
   Bit #(8)      keep;
   TLPFirstDWBE  first_be;
   TLPFirstDWBE  last_be;
} AxiStCq deriving (Bits, Eq);

typedef struct {
   Bit #(256)    data;
   Bit #(8)      keep;
   Bool          last;
} AxiStCc deriving (Bits, Eq);

typedef struct {
   Bit #(256)    data;
   Bool          last;
   Bit #(8)      keep;
   Bit #(4)      first_be;
   Bit #(4)      last_be;
} AxiStRq deriving (Bits, Eq);

typedef struct {
   Bit #(256)    data;
   Bool          sop;
   Bool          eop;
   Bit #(8)      keep;
   Bit #(8)      be;
} AxiStRc deriving (Bits, Eq);

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

   FIFOF#(AxiStRc) fAxiRc <- mkBypassFIFOF(clocked_by pcie_ep.user_clk, reset_by noReset);
   FIFOF#(AxiStCq) fAxiCq <- mkBypassFIFOF(clocked_by pcie_ep.user_clk, reset_by noReset);
   FIFOF#(AxiStRq) fAxiRq <- mkBypassFIFOF(clocked_by pcie_ep.user_clk, reset_by noReset);
   FIFOF#(AxiStCc) fAxiCc <- mkBypassFIFOF(clocked_by pcie_ep.user_clk, reset_by noReset);

   FIFOF#(TLPData#(16)) fcq <- mkFIFOF(clocked_by pcie_ep.user_clk, reset_by noReset);
   FIFOF#(TLPData#(16)) frc <- mkFIFOF(clocked_by pcie_ep.user_clk, reset_by noReset);
   FIFOF#(TLPData#(16)) fcc <- mkFIFOF(clocked_by pcie_ep.user_clk, reset_by noReset);
   FIFOF#(TLPData#(16)) frq <- mkFIFOF(clocked_by pcie_ep.user_clk, reset_by noReset);

   // Drive s_axis_rq
   let rq_txready = (pcie_ep.s_axis_rq.tready != 0 && fAxiRq.notEmpty);

   //(* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_rq if (rq_txready);
      let info = fAxiRq.first; fAxiRq.deq;
      pcie_ep.s_axis_rq.tvalid(1);
      pcie_ep.s_axis_rq.tlast(pack(info.last));
      pcie_ep.s_axis_rq.tdata(info.data);
      pcie_ep.s_axis_rq.tkeep(info.keep);
      pcie_ep.s_axis_rq.tuser({0, info.last_be, info.first_be});
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
   let cc_txready = (pcie_ep.s_axis_cc.tready != 0 && fAxiCc.notEmpty);

   //(* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_cc if (cc_txready);
      let info = fAxiCc.first; fAxiCc.deq;
      pcie_ep.s_axis_cc.tvalid(1);
      pcie_ep.s_axis_cc.tlast(pack(info.last));
      pcie_ep.s_axis_cc.tdata(info.data);
      pcie_ep.s_axis_cc.tkeep(info.keep);
      pcie_ep.s_axis_cc.tuser(0);
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_cc2 if (!cc_txready);
      pcie_ep.s_axis_cc.tvalid(0);
      pcie_ep.s_axis_cc.tlast(0);
      pcie_ep.s_axis_cc.tdata(0);
      pcie_ep.s_axis_cc.tkeep(0);
      pcie_ep.s_axis_cc.tuser(0);
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_rc_ready;
      pcie_ep.m_axis_rc.tready (duplicate (pack (fAxiRc.notFull)));
   endrule
 
   // Drive m_axis_rc
   (* fire_when_enabled *)
   rule sink_axi_rc if (pcie_ep.m_axis_rc.tvalid != 0 && fAxiRc.notFull);
      let rc = AxiStRc {data:pcie_ep.m_axis_rc.tdata,
			sop: unpack (pcie_ep.m_axis_rc.tuser [32]),         // tuser.is_sof_0
			eop: unpack (pcie_ep.m_axis_rc.tlast),
			keep:pcie_ep.m_axis_rc.tkeep,
			be:  truncate (pcie_ep.m_axis_rc.tuser [31:0])};    // tuser.byte_en
      fAxiRc.enq (rc);
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_cq_ready;
      pcie_ep.m_axis_cq.tready (duplicate (pack (fAxiCq.notFull)));
   endrule

   (* fire_when_enabled *)
   rule sink_axi_cq if (pcie_ep.m_axis_cq.tvalid != 0 && fAxiCq.notFull);
      let cq = AxiStCq {data:     pcie_ep.m_axis_cq.tdata,
			sop:      unpack (pcie_ep.m_axis_cq.tuser [40]),  // tuser.sop
			eop:      unpack (pcie_ep.m_axis_cq.tlast),
			keep:     pcie_ep.m_axis_cq.tkeep,
			first_be: pcie_ep.m_axis_cq.tuser [3:0],    // tuser.first_be,
			last_be:  pcie_ep.m_axis_cq.tuser [7:4]};   // tuser.last_be
      fAxiCq.enq (cq);
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

   // CQ.
   CQDescriptor cq_desc = unpack(fAxiCq.first.data [127:0]);

   rule rl_cq_wr_header (fAxiCq.first.sop && ((cq_desc.reqtype == MEMORY_WRITE) || (cq_desc.reqtype == IO_WRITE)));
      Bit#(32) data = fAxiCq.first.data[127:96];
      // get data;
      TLPData#(16) tlp16 = convertCQDescriptorToTLP16(cq_desc, data, fAxiCq.first.first_be, fAxiCq.first.last_be);
      // enqueue?
      fcq.enq(tlp16);
      fAxiCq.deq;
   endrule

   // Write data payload, no data remaining
   rule rl_cq_wr_payload((!fAxiCq.first.sop));
      fAxiCq.deq;
   endrule

   // Write data payload, 1 to 3 DWs remaining
   // Write data payload, 4 or more DWs remaining

   rule rl_cq_rd_header (fAxiCq.first.sop && ((cq_desc.reqtype == MEMORY_READ) || (cq_desc.reqtype == IO_READ)));
      Bit#(32) data = 0;
      TLPData#(16) tlp16 = convertCQDescriptorToTLP16(cq_desc, data, fAxiCq.first.first_be, fAxiCq.first.last_be);
      fcq.enq(tlp16);
      fAxiCq.deq;
   endrule

   // RC.
   Reg#(DWCount) rg_dwcount <- mkRegU(clocked_by pcie_ep.user_clk, reset_by reset250);

   rule rl_rc_header (fAxiRc.first.sop);
      RCDescriptor rc_desc = unpack(fAxiRc.first.data [95:0]);
      Bit#(32) data = fAxiRc.first.data[31:0];
      TLPData#(16) tlp16 = convertRCDescriptorToTLP16(rc_desc, data);
      rg_dwcount <= (rc_desc.dwcount == 0) ? 0 : rc_desc.dwcount - 1;
      frc.enq(tlp16);
      fAxiRc.deq;
   endrule

   rule rl_rc_data ((!(fAxiRc.first.sop)) && (rg_dwcount != 0));
      Bit#(16) be16;
      case (rg_dwcount)
         1: be16 = 16'hF000;
         2: be16 = 16'hFF00;
         3: be16 = 16'hFFF0;
         default: be16 = 16'hFFFF;
      endcase
      TLPData#(16) tlp16 = TLPData{sof: False,
                                   eof: (rg_dwcount <= 4),
                                   hit: 0,
                                   be: be16,
                                   data: pack(fAxiRc.first.data[127:0])};
      frc.enq(tlp16);
      fAxiRc.deq;
   endrule

   Reg#(DWCount) cc_dwcount <- mkReg(0, clocked_by pcie_ep.user_clk, reset_by reset250);
   FIFOF#(TLPData#(16)) fcc_tlps <- mkPipelineFIFOF (clocked_by pcie_ep.user_clk, reset_by reset250);
   // CC.
   rule get_cc_tlps;
      let tlp <- toGet(fcc).get;
      fcc_tlps.enq(tlp);
   endrule

   rule rl_cc_header(fcc_tlps.first.sof);
      match { .cc_desc, .dw} = convertTLP16ToCCDescriptor(fcc_tlps.first);
      cc_dwcount <= cc_desc.dwcount - 1;
      fAxiCc.enq(AxiStCc {data: {dw, zeroExtend(pack(cc_desc))}, //FIXME
                       last: fcc_tlps.first.eof,
                       keep: 8'hFF});
      fcc_tlps.deq;
   endrule

   rule rl_cc_data((!fcc_tlps.first.sof) && (cc_dwcount != 0));
      Bit#(256) x = zeroExtend(fcc_tlps.first.data); //FIXME
      fAxiCc.enq(AxiStCc {data: {x},
                       last: cc_dwcount <= 4,
                       keep: (cc_dwcount == 3) ? 8'h0F : 8'hFF});
      fcc_tlps.deq;
   endrule

   // RQ.
   FIFOF#(TLPData#(16)) frq_tlps <- mkPipelineFIFOF (clocked_by pcie_ep.user_clk, reset_by reset250);
   Reg#(DWCount) rq_dwcount <- mkReg(0, clocked_by pcie_ep.user_clk, reset_by reset250);
   Reg#(Maybe#(Bit#(32))) rq_mdw <- mkRegU(clocked_by pcie_ep.user_clk, reset_by reset250);
   Reg#(Bit#(4)) rq_first_be <- mkRegU(clocked_by pcie_ep.user_clk, reset_by reset250);
   Reg#(Bit#(4)) rq_last_be <- mkRegU(clocked_by pcie_ep.user_clk, reset_by reset250);
   rule get_rq_tlps;
      let tlp <- toGet(frq).get;
      frq_tlps.enq(tlp);
   endrule

   rule rl_rq_header(frq_tlps.first.sof);
      match { .rq_desc, .first_be, .last_be, .mdata} = convertTLP16ToRQDescriptor(frq_tlps.first);
      rq_dwcount <= ((rq_desc.reqtype == MEMORY_WRITE) ? rq_desc.dwcount : 0);
      rq_mdw <= mdata;
      rq_first_be <= first_be;
      rq_last_be <= last_be;
      fAxiRq.enq(AxiStRq {data: zeroExtend(pack(rq_desc)), //FIXME:
                       last: frq_tlps.first.eof,
                       keep: 8'hFF,
                       first_be: first_be,
                       last_be: last_be});
      frq_tlps.deq;
   endrule

   // rq_mdw contains last DW
   rule rl_rq_data_a (rq_mdw matches tagged Valid .dw &&& (rq_dwcount == 1));
      rq_dwcount <= 0;
      rq_mdw <= tagged Invalid;
   endrule

   // rq_mdw Valid, and there are more DWs.
   rule rl_rq_data_b(rq_mdw matches tagged Valid .dw &&& (rq_dwcount != 1));

   endrule

   // rq_mdw Invalid, and there are more DWs.
   rule rl_rq_data_c(rq_mdw matches tagged Invalid &&& (rq_dwcount != 1));

   endrule
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
   // The PCIE endpoint is processing Gen3 descriptors at 250MHz. The
   // AXI bridge is accepting TLPData#(16)s at 250 MHz. The
   // conversion uses half of Gen3 descriptor.
   //mkConnection(tlp8, gb.tlp, clocked_by portalClock, reset_by portalReset);

   interface Server tlpr;
      interface request = toPut(frc);
      interface response = toGet(frq);
   endinterface
   interface Server tlpc;
      interface request = toPut(fcc);
      interface response = toGet(fcq);
   endinterface
   interface pcie    = pcie_ep.pci_exp;
   interface Pcie3wrapUser user = pcie_ep.user;
   interface PciewrapPipe pipe = pcie_ep.pipe;
   interface PciewrapCommon common= pcie_ep.common;
   interface Clock epClock125 = clock125;
   interface Reset epReset125 = reset125;
   interface Clock epClock250 = clock250;
   interface Reset epReset250 = reset250;
   interface Clock epPcieClock = clock250;
   interface Reset epPcieReset = reset250;
   interface Clock epPortalClock = portalClock;
   interface Reset epPortalReset = portalReset;
   interface Clock epDerivedClock = derivedClock;
   interface Reset epDerivedReset = derivedReset;
endmodule: mkPcieEndpointX7

endpackage: Pcie3EndpointX7
