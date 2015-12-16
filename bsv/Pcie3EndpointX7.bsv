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

package Pcie3EndpointX7;

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
import CFFIFO            ::*;
import SpecialFIFOs      ::*;
import ClientServer      ::*;
import Real              ::*;
import XilinxVirtex7PCIE ::*;
import BUtils            ::*;
import Probe             ::*;

import ConnectalConfig::*;
import ConnectalClocks   ::*;
import ConnectalXilinxCells   ::*;
import XilinxCells       ::*;
import PCIE              ::*;
import PCIEWRAPPER3      ::*;
import Bufgctrl           ::*;
import PcieGearbox       :: *;
import Pipe              :: *;

interface PcieEndpointX7#(numeric type lanes);
   interface PciewrapPci_exp#(lanes)           pcie;
   interface PciewrapUser#(lanes)              user;
   interface PciewrapPipe#(lanes)              pipe;
   interface PciewrapCommon#(lanes)            common;
   interface Server#(TLPData#(TlpDataBytes), TLPData#(TlpDataBytes)) tlpr;
   interface Server#(TLPData#(16), TLPData#(16)) tlpc;
   interface Put#(Tuple2#(Bit#(64),Bit#(32)))  interruptRequest;
   interface PipeOut#(Bit#(64)) regChanges;
   interface Clock epPcieClock;
   interface Reset epPcieReset;
   interface Clock epPortalClock;
   interface Reset epPortalReset;
   interface Clock epDerivedClock;
   interface Reset epDerivedReset;
endinterface

typedef struct {
   Bit #(256)     data;
   Bool          sop;
   Bool          eop;
   Bit #(8)      keep;
   TLPFirstDWBE  first_be;
   TLPFirstDWBE  last_be;
} AxiStCq deriving (Bits, Eq);

typedef struct {
   Bit #(256)     data;
   Bit #(8)      keep;
   Bool          last;
} AxiStCc deriving (Bits, Eq);

typedef struct {
   Bit #(256)     data;
   Bool          last;
   Bit #(8)      keep;
   Bit #(4)      first_be;
   Bit #(4)      last_be;
} AxiStRq deriving (Bits, Eq);

typedef struct {
   Bit #(256)     data;
   Bool          sop;
   Bool          eop;
   Bit #(8)      keep;
   Bit #(8)      be;
} AxiStRc deriving (Bits, Eq);

function TLPData#(16) convertCQDescriptorToTLP16(CQDescriptor desc, Bit#(32) data, TLPFirstDWBE first, TLPLastDWBE last);
   TLPMemoryIO3DWHeader header = defaultValue;
   header.format     = tpl_1(convertCQReqTypeToTLPFmtType(desc.reqtype));
   header.pkttype    = tpl_2(convertCQReqTypeToTLPFmtType(desc.reqtype));
   header.tclass     = desc.tclass;
   header.relaxed    = desc.relaxed;
   header.nosnoop    = desc.nosnoop;
   header.length     = (desc.dwcount == 1024) ? 0 : truncate(desc.dwcount);
   header.reqid      = desc.reqid;
   header.tag        = desc.tag;
   header.lastbe     = last;
   header.firstbe    = first;
   header.addr       = truncate(desc.address);
   header.data       = convertDW(data);
   
   Bool is3DW = isReadReqType(desc.reqtype);
   Bool is3Or4DW = isReadReqType(desc.reqtype) || (desc.dwcount == 1);

   TLPData#(16) retval = defaultValue;
   retval.sof   = True;
   retval.eof   = is3Or4DW;
   retval.hit   = (1 << pack(desc.barid));
   retval.data  = pack(header);
   retval.be    = (is3DW ? 16'hFFF0 : 16'hFFFF);
   
   return retval;
endfunction

function Tuple4 #(RQDescriptor,
		  TLPFirstDWBE,
		  TLPLastDWBE,
		  Maybe#(Bit#(32)))
         convertTLP16ToRQDescriptor (TLPData #(TlpDataBytes) header);

   // Note: other than .addr and .data, remaining fields are same for
   // the two header formats below
   TLPMemoryIO3DWHeader header3dw = unpack(truncate(header.data));
   TLPMemory4DWHeader   header4dw = unpack(truncate(header.data));
   RQDescriptor desc = unpack(0);
   Maybe#(Bit#(32)) data = tagged Invalid;
   
   desc.relaxed      = header4dw.relaxed;
   desc.nosnoop      = header4dw.nosnoop;
   desc.tclass       = header4dw.tclass;
   desc.reqiden      = False;
   desc.tag          = header4dw.tag;
   desc.reqid        = header4dw.reqid;
   desc.poisoned     = header4dw.poison;
   case(header4dw.format)
      MEM_READ_3DW_NO_DATA: desc.reqtype = MEMORY_READ;
      MEM_READ_4DW_NO_DATA: desc.reqtype = MEMORY_READ;
      MEM_WRITE_3DW_DATA:   desc.reqtype = MEMORY_WRITE;
      MEM_WRITE_4DW_DATA:   desc.reqtype = MEMORY_WRITE;
      default:              desc.reqtype = MEMORY_READ;
   endcase
   desc.dwcount      = (header4dw.length == 0) ? 1024 : zeroExtend(header4dw.length);
   
   if (header4dw.format == MEM_WRITE_4DW_DATA || header4dw.format == MEM_READ_4DW_NO_DATA) begin
      desc.address      = header4dw.addr;
   end
   else begin
      desc.address      = zeroExtend(header3dw.addr);
      if (header3dw.format == MEM_WRITE_3DW_DATA) begin
	 data           = tagged Valid convertDW(header3dw.data);
      end
   end
   
   return tuple4 (desc, header4dw.firstbe, header4dw.lastbe, data);
endfunction

function TLPData#(TlpDataBytes) convertRCDescriptorToTLP16(RCDescriptor desc, Vector#(TSub#(TlpDataWords,3),Bit#(32)) data);
   TLPCompletionHeader header = defaultValue;
   header.tclass    = desc.tclass;
   header.relaxed   = desc.relaxed;
   header.nosnoop   = desc.nosnoop;
   header.cmplid    = desc.complid;
   header.tag       = desc.tag;
   header.reqid     = desc.reqid;
   header.poison    = desc.poisoned;
   header.cstatus   = desc.status;
   header.length    = (desc.dwcount == 1024) ? 0 : truncate(desc.dwcount);
   header.bytecount = (desc.bytecount == 4096) ? 0 : truncate(desc.bytecount);
   header.loweraddr = truncate(desc.loweraddr);
   header.data      = data[0];

   Bool is3DW = (desc.dwcount == 0);
   Bool is3Or4DW = (desc.dwcount == 0) || (desc.dwcount == 1);
   TLPData#(TlpDataBytes) retval = defaultValue;
   retval.sof   = True;
   retval.eof   = is3Or4DW;
   retval.hit   = 1; // XXX
   retval.data  = {pack(takeAt(1,data)), pack(header)};
   let maxwords = fromInteger(valueOf(TSub#(TlpDataWords,3)));
   retval.be    = maxBound << (4 * (maxwords - max(desc.dwcount, maxwords)));
   
   return retval;
endfunction

typedef struct {
   Bit#(32) timestamp;
   Bit#(8) src;
   Bit#(24) value;
} RegChange deriving (Bits);

typedef enum {
   Pcie3Cfg_none,
   Pcie3Cfg_current_speed,
   Pcie3Cfg_dpa_substate_change,
   Pcie3Cfg_err_cor_out,
   Pcie3Cfg_err_fatal_out,
   Pcie3Cfg_err_nonfatal_out,
   Pcie3Cfg_flr_in_process,
   Pcie3Cfg_function_power_state,
   Pcie3Cfg_function_status,
   Pcie3Cfg_hot_reset_out,
   Pcie3Cfg_link_power_state,
   Pcie3Cfg_ltr_enable,
   Pcie3Cfg_ltssm_state,
   Pcie3Cfg_max_payload,
   Pcie3Cfg_max_read_req,
   Pcie3Cfg_negotiated_width,
   Pcie3Cfg_obff_enable,
   Pcie3Cfg_phy_link_down,
   Pcie3Cfg_phy_link_status,
   Pcie3Cfg_pl_status_change,
   Pcie3Cfg_power_state_change_interrupt,
   Pcie3Cfg_rcb_status,
   Pcie3Cfg_rq_backpressure
   } Pcie3CfgType deriving (Bits,Eq);

(* synthesize *)
module mkPcieEndpointX7(PcieEndpointX7#(PcieLanes));

   PCIEParams params = defaultValue;
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
   Reset defaultResetInverted <- mkResetInverter(defaultReset, clocked_by defaultClock);
   PcieWrap#(PcieLanes) pcie_ep <- mkPcieWrap(defaultClock, defaultResetInverted);

   // The PCIe endpoint exports full (250MHz) and half-speed (125MHz) clocks
   Clock pcieClock250 = pcie_ep.user_clk;
   Reset user_reset_n <- mkResetInverter(pcie_ep.user_reset, clocked_by pcie_ep.user_clk);
   Reset pcieReset250 <- mkAsyncReset(4, user_reset_n, pcieClock250);

   ClockGenerator7Params     clkgenParams = defaultValue;
   clkgenParams.clkin1_period    = 4.000; //  250MHz
   clkgenParams.clkin1_period    = 4.000;
   clkgenParams.clkin_buffer     = False;
   clkgenParams.clkfbout_mult_f  = 4.000; // 1000MHz
   clkgenParams.clkout0_divide_f = derivedClockPeriod;
   clkgenParams.clkout1_divide     = round(mainClockPeriod);
   clkgenParams.clkout1_duty_cycle = 0.5;
   clkgenParams.clkout1_phase      = 0.0000;
   ClockGenerator7           clkgen <- mkClockGenerator7(clkgenParams, clocked_by pcieClock250, reset_by pcieReset250);
   Clock mainClock = clkgen.clkout1;
   Reset mainReset <- mkAsyncReset(4, pcieReset250, mainClock);
   Clock derivedClock = clkgen.clkout0;
   Reset derivedReset <- mkAsyncReset(4, pcieReset250, derivedClock);
   Reset user_reset <- mkAsyncReset(2, pcie_ep.user_reset, pcie_ep.user_clk);

   // FIFOS
   FIFOF#(AxiStCq) fAxiCq <- mkFIFOF(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   FIFOF#(AxiStRc) fAxiRc <- mkCFFIFOF(clocked_by pcie_ep.user_clk, reset_by user_reset_n);

   FIFOF#(AxiStRq) fAxiRq <- mkCFFIFOF(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   FIFOF#(AxiStCc) fAxiCc <- mkFIFOF(clocked_by pcie_ep.user_clk, reset_by user_reset_n);

   FIFOF#(TLPData#(16)) fcq <- mkFIFOF(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   FIFOF#(TLPData#(TlpDataBytes)) frc <- mkFIFOF(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   FIFOF#(TLPData#(16)) fcc <- mkFIFOF(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   FIFOF#(TLPData#(TlpDataBytes)) frq <- mkFIFOF(clocked_by pcie_ep.user_clk, reset_by user_reset_n);

   FIFOF#(Tuple2#(Bit#(64),Bit#(32))) intrFifo <- mkFIFOF(clocked_by pcie_ep.user_clk, reset_by user_reset_n);

   let probe_axi_rq_data <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_axi_rq_last <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_axi_rq_keep <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);

   let probe_rc_dwcount <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_rc_be <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_rc_upper_data <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_rc_lower_data <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_rc_sop <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_rc_eop <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_rc_keep <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);

   let probe_tlp16_upper_data <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_tlp16_lower_data <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);

   let probe_rq_last <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_rq_address <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_rq_dwcount <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_rq_even <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_rq_upper_data <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_rq_lower_data <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_rq_keep <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);

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

      probe_axi_rq_data <= info.data;
      probe_axi_rq_keep <= info.keep;
      probe_axi_rq_last <= info.last;
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_rq2 if (!rq_txready);
      pcie_ep.s_axis_rq.tvalid(0);
      pcie_ep.s_axis_rq.tlast(0);
      pcie_ep.s_axis_rq.tdata(0);
      pcie_ep.s_axis_rq.tkeep(0);
      pcie_ep.s_axis_rq.tuser(0);
   endrule

   Reg#(Bit#(16)) rqBackpressureCycles <- mkReg(0, clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   Reg#(Bit#(16)) rqBackpressureCount <- mkReg(0, clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   Reg#(Bool)     rqBackpressure       <- mkReg(False, clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   Reg#(Bit#(32)) rqBackpressureCountSum <- mkReg(0, clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   Reg#(Bit#(32)) rqBackpressureEvents   <- mkReg(0, clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_rqBackpressureCycles <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_rqBackpressureCount <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_rqBackpressure       <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   Probe#(Bit#(32)) probe_rqBackpressureCountSum <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   Probe#(Bit#(32)) probe_rqBackpressureEvents   <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_fAxiRqNotEmpty       <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   let probe_SAxsiRqTReady        <- mkProbe(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   rule rltready;
      probe_fAxiRqNotEmpty <= fAxiRq.notEmpty();
      probe_SAxsiRqTReady <= pcie_ep.s_axis_rq.tready;
   endrule
   rule rlBackpressureEnter if (!rqBackpressure);
      if (pcie_ep.s_axis_rq.tready == 0 && fAxiRq.notEmpty) begin
	 rqBackpressure <= True;
	 rqBackpressureCycles <= 0;
	 probe_rqBackpressure <= True;
	 probe_rqBackpressureCycles <= 0;
      end
   endrule
   rule rlBackpressureExit if (rqBackpressure);
      rqBackpressureCycles <= rqBackpressureCycles + 1;
      probe_rqBackpressureCycles <= rqBackpressureCycles + 1;
      if (pcie_ep.s_axis_rq.tready != 0 || !fAxiRq.notEmpty) begin
	 rqBackpressure <= False;
	 let count = rqBackpressureCycles;
	 count[15] = ~rqBackpressureCount[15];
	 if (count > 5)
	    rqBackpressureCount <= count;
	 rqBackpressureCountSum <= rqBackpressureCountSum + extend(count);
	 rqBackpressureEvents <= rqBackpressureEvents + 1;
	 probe_rqBackpressure <= False;
	 probe_rqBackpressureCount <= count;
	 probe_rqBackpressureCountSum <= rqBackpressureCountSum + extend(count);
	 probe_rqBackpressureEvents <= rqBackpressureEvents + 1;
      end
      else begin
	 probe_rqBackpressure <= True;
      end
   endrule

   // Drive s_axis_cc
   let cc_txready = (pcie_ep.s_axis_cc.tready != 0 && fAxiCc.notEmpty);

   //(* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_cc if (cc_txready);
      let info = fAxiCc.first; fAxiCc.deq;
      $display("drive axi_cc, data: %h, keep: %h, last: %h", info.data, info.keep, info.last);
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
      probe_rc_upper_data <= (rc.data >> 128)[127:0];
      probe_rc_lower_data <= (rc.data >>   0)[127:0];
      probe_rc_sop <= rc.sop;
      probe_rc_eop <= rc.eop;
      probe_rc_keep <= rc.keep;
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

   // CQ.
   CQDescriptor cq_desc = unpack(fAxiCq.first.data [127:0]);

   rule rl_cq_wr_header (fAxiCq.first.sop && ((cq_desc.reqtype == MEMORY_WRITE) || (cq_desc.reqtype == IO_WRITE)));
      Bit#(32) data = fAxiCq.first.data[159:128];
      // get data;
      TLPData#(16) tlp16 = convertCQDescriptorToTLP16(cq_desc, data, fAxiCq.first.first_be, fAxiCq.first.last_be);
      $display("cq_desc.reqtype=%h", cq_desc.reqtype);
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
      $display("rl_cq_rd_header: cq_desc = %16x", cq_desc);
      fcq.enq(tlp16);
      fAxiCq.deq;
   endrule

   // RC.
   Reg#(DWCount) rc_dwcount <- mkRegU(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   Reg#(Bool) rc_even <- mkReg(True, clocked_by pcie_ep.user_clk, reset_by user_reset_n);

   rule rl_rc_header (fAxiRc.first.sop && rc_even);
      RCDescriptor rc_desc = unpack(fAxiRc.first.data [95:0]);
      // RC descriptor always 96 bytes with first data word in bits 127:96                                                                                            
      Vector#(TlpDataWords,Bit#(32)) datavec = unpack(fAxiRc.first.data);
      TLPData#(TlpDataBytes) tlp16 = convertRCDescriptorToTLP16(rc_desc, takeAt(3,datavec));
      let tlpDataWords = fromInteger(valueOf(TlpDataWords));
      let wordsConsumed = min(rc_desc.dwcount, tlpDataWords-3);
      let count = (rc_desc.dwcount == 0) ? 0 : rc_desc.dwcount - wordsConsumed;
      rc_dwcount <= count;
      probe_rc_dwcount <= count;
      probe_tlp16_upper_data <= (tlp16.data >> 128)[127:0];
      probe_tlp16_lower_data <= (tlp16.data >> 0)[127:0];
      probe_rc_be <= tlp16.be;
      frc.enq(tlp16);
      let even = False;
      if (rc_desc.dwcount <= tlpDataWords-3 || tlpDataWords > 4) begin
        fAxiRc.deq;
        even = True;
      end
      rc_even <= even;
   endrule

   rule rl_rc_data ((!rc_even || !(fAxiRc.first.sop) || valueOf(TlpDataWords) > 4) && (rc_dwcount != 0));
      let tlpDataWords = fromInteger(valueOf(TlpDataWords));
      Bit#(TlpDataBytes) be16 = maxBound << (4*(tlpDataWords-min(tlpDataWords,rc_dwcount)));
      let last = (rc_dwcount <= tlpDataWords);
      let dwcount = rc_dwcount - tlpDataWords;
      if (last) dwcount = 0;
      let data = (rc_even || tlpDataWords > 4) ? extend(fAxiRc.first.data) : extend(fAxiRc.first.data >> 128);
      TLPData#(TlpDataBytes) tlp16 = TLPData{sof: False,
					     eof: last,
					     hit: 0,
					     be: be16,
					     data: data};
      probe_tlp16_upper_data <= (tlp16.data >> 128)[127:0];
      probe_tlp16_lower_data <= (tlp16.data >> 0)[127:0];
      frc.enq(tlp16);
      if (last || !rc_even || tlpDataWords > 4) begin
         fAxiRc.deq;
      end
      rc_dwcount <= dwcount;
      probe_rc_dwcount <= dwcount;
      rc_even <= (last) ? True : (!rc_even || valueOf(TlpDataWords) > 4);
   endrule

   Reg#(DWCount) cc_dwcount <- mkReg(0, clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   FIFOF#(TLPData#(16)) fcc_tlps <- mkFIFOF (clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   // CC.
   rule get_cc_tlps;
      let tlp <- toGet(fcc).get;
      fcc_tlps.enq(tlp);
   endrule

   rule rl_cc_header(fcc_tlps.first.sof);
      match { .cc_desc, .dw} = convertTLP16ToCCDescriptor(fcc_tlps.first);
      cc_dwcount <= cc_desc.dwcount - 1;
      fAxiCc.enq(AxiStCc {data: zeroExtend({dw, pack(cc_desc)[95:0]}),
                       last: fcc_tlps.first.eof,
                       keep: 8'h0F});
      fcc_tlps.deq;
   endrule

   rule rl_cc_data((!fcc_tlps.first.sof) && (cc_dwcount != 0));
      Bit#(256) x = zeroExtend(fcc_tlps.first.data); //FIXME multiword CPU read/write request
      fAxiCc.enq(AxiStCc {data: {x},
                       last: cc_dwcount <= 4,
                       keep: (cc_dwcount == 3) ? 8'h0F : 8'hFF});
      fcc_tlps.deq;
   endrule

   // RQ.
   FIFOF#(TLPData#(TlpDataBytes)) frq_tlps <- mkFIFOF (clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   Reg#(Bit#(4)) rq_first_be <- mkReg(0, clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   Reg#(Bit#(4)) rq_last_be <- mkReg(0, clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   Reg#(Bool)    rq_even    <- mkRegU(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   Reg#(DWCount) rq_dwcount <- mkReg(0, clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   Reg#(AxiStRq) rq_rq <- mkRegU(clocked_by pcie_ep.user_clk, reset_by user_reset_n);

   rule rl_rq_tlps;
      let tlp <- toGet(frq).get;
      frq_tlps.enq(tlp);
   endrule

   rule rl_rq_header if (frq_tlps.first.sof);
      TLPData#(TlpDataBytes) tlp <- toGet(frq_tlps).get();
      match { .rq_desc, .first_be, .last_be, .mdata} = convertTLP16ToRQDescriptor(tlp);

      let dwcount = ((rq_desc.reqtype == MEMORY_WRITE) ? rq_desc.dwcount : 0);
      Bit#(4) keep = (1 << dwcount) - 1;
      let last = (rq_desc.reqtype == MEMORY_WRITE) ? (dwcount <= 4) : True;
      Bit#(128) upper_data = truncate(tlp.data >> 128);
      let tlpDataWords = fromInteger(valueOf(TlpDataWords));
      if (tlpDataWords > 4)
	 dwcount = dwcount - min(tlpDataWords/2, dwcount);

      let rq = AxiStRq {data: {upper_data, pack(rq_desc)},
			last: last,
			keep: {keep,4'hf},
			first_be: first_be,
			last_be: last_be};
      if (rq_desc.reqtype == MEMORY_WRITE && tlpDataWords <= 4)
	 rq_rq <= rq;
      else
	 fAxiRq.enq(rq);
      rq_dwcount <= dwcount;
      rq_even <= False;
      rq_first_be <= first_be;
      rq_last_be <= last_be;

      probe_rq_last <= last;
      probe_rq_address <= rq_desc.address;
      probe_rq_dwcount <= dwcount;
      probe_rq_upper_data <= upper_data;
      probe_rq_lower_data <= pack(rq_desc);
      probe_rq_keep <= rq.keep;
      probe_rq_even <= False;
   endrule

   // more data
   rule rl_rq_data if (rq_dwcount != 0);
      TLPData#(TlpDataBytes) tlp <- toGet(frq_tlps).get();
      let rq = rq_rq;
      let tlpDataWords = fromInteger(valueOf(TlpDataWords));
      let last = (rq_dwcount <= tlpDataWords);
      let dwcount = rq_dwcount - tlpDataWords;
      Bit#(8) keep;
      if (last)
	dwcount = 0;
      if (rq_even || tlpDataWords > 4) begin
	 rq.data = extend(tlp.data);
	 keep = (1 << rq_dwcount) - 1;
      end
      else begin
	rq.data = extend(tlp.data) << 128;
	case (rq_dwcount)
	   1: keep = 8'h1f;
	   2: keep = 8'h3f;
	   3: keep = 8'h7f;
	   default: keep = 8'hff;
	endcase
      end
      rq.last = last;
      rq.first_be = rq_first_be;
      rq.last_be = rq_last_be;
      rq.keep = keep;

      probe_rq_last <= last;
      probe_rq_keep <= keep;
      probe_rq_upper_data <= truncate(tlp.data >> 128);
      probe_rq_lower_data <= truncate(tlp.data >> 0);

      if (!rq_even || last || tlpDataWords > 4)
	 fAxiRq.enq(rq);
      if (rq_even)
	rq_rq <= rq;
      rq_dwcount <= dwcount;
      rq_even <= (last) ? False : !rq_even;

      probe_rq_dwcount <= dwcount;
      probe_rq_even <= (last) ? False : !rq_even;
   endrule

   FIFO#(Bool) intrMutex <- mkFIFO1(clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   Wire#(Bool) msix_int_enable <- mkDWire(False, clocked_by pcie_ep.user_clk, reset_by user_reset_n);

   rule rl_intr;
      if (pcie_ep.cfg.interrupt_msix_enable[0] == 1) begin
	 match { .addr, .data } <- toGet(intrFifo).get();
	 pcie_ep.cfg.interrupt_msix_address(addr);
	 pcie_ep.cfg.interrupt_msix_data(data);
	 msix_int_enable <= True;
	 intrMutex.enq(True);
      end
   endrule: rl_intr
   rule rl_intr_enable;
      pcie_ep.cfg.interrupt_msix_int(pack(msix_int_enable));
   endrule

   rule rl_intr_sent if (pcie_ep.cfg.interrupt_msix_sent() == 1|| pcie_ep.cfg.interrupt_msix_fail() == 1);
      intrMutex.deq();
   endrule

   Reg#(Bit#(32)) cyclesReg <- mkReg(0, clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   rule rl_cycles;
      cyclesReg <= cyclesReg + 1;
   endrule

   module mkChangeSource#(Tuple2#(Pcie3CfgType,Bit#(24)) tpl)(PipeOut#(RegChange));
      match { .src, .v } = tpl;
      let snapshot <- mkReg(0);
      let changeFifo <- mkFIFOF1();
      rule rl_update if (v != snapshot);
	 if (changeFifo.notFull) begin
	    changeFifo.enq(RegChange { timestamp: cyclesReg, src: extend(pack(src)), value: extend(v) });
	    snapshot <= v;
	 end
      endrule
      return toPipeOut(changeFifo);
   endmodule

`ifndef FOO
   Vector#(20,Tuple2#(Pcie3CfgType,Bit#(24))) changeValues = vec(
      tuple2(Pcie3Cfg_rq_backpressure, extend(rqBackpressureCount)),
      tuple2(Pcie3Cfg_current_speed, extend(pcie_ep.cfg.current_speed)),
      tuple2(Pcie3Cfg_dpa_substate_change, extend(pcie_ep.cfg.dpa_substate_change)),
      tuple2(Pcie3Cfg_err_cor_out, extend(pcie_ep.cfg.err_cor_out)),
      tuple2(Pcie3Cfg_err_fatal_out, extend(pcie_ep.cfg.err_fatal_out)),
      tuple2(Pcie3Cfg_err_nonfatal_out, extend(pcie_ep.cfg.err_nonfatal_out)),
      tuple2(Pcie3Cfg_flr_in_process, extend(pcie_ep.cfg.flr_in_process)),
      tuple2(Pcie3Cfg_function_power_state, extend(pcie_ep.cfg.function_power_state)),
//      tuple2(Pcie3Cfg_function_status, extend(pcie_ep.cfg.function_status)),
      tuple2(Pcie3Cfg_hot_reset_out, extend(pcie_ep.cfg.hot_reset_out)),
      tuple2(Pcie3Cfg_link_power_state, extend(pcie_ep.cfg.link_power_state)),
      tuple2(Pcie3Cfg_ltr_enable, extend(pcie_ep.cfg.ltr_enable)),
//      tuple2(Pcie3Cfg_ltssm_state, extend(pcie_ep.cfg.ltssm_state)),
      tuple2(Pcie3Cfg_max_payload, extend(pcie_ep.cfg.max_payload)),
      tuple2(Pcie3Cfg_max_read_req, extend(pcie_ep.cfg.max_read_req)),
      tuple2(Pcie3Cfg_negotiated_width, extend(pcie_ep.cfg.negotiated_width)),
      tuple2(Pcie3Cfg_obff_enable, extend(pcie_ep.cfg.obff_enable)),
      tuple2(Pcie3Cfg_phy_link_down, extend(pcie_ep.cfg.phy_link_down)),
      tuple2(Pcie3Cfg_phy_link_status, extend(pcie_ep.cfg.phy_link_status)),
      tuple2(Pcie3Cfg_pl_status_change, extend(pcie_ep.cfg.pl_status_change)),
      tuple2(Pcie3Cfg_power_state_change_interrupt, extend(pcie_ep.cfg.power_state_change_interrupt)),
      tuple2(Pcie3Cfg_rcb_status, extend(pcie_ep.cfg.rcb_status)));
   let change_pipes <- mapM(mkChangeSource, changeValues, clocked_by pcie_ep.user_clk, reset_by user_reset_n);

   FunnelPipe#(1,20,RegChange,3) changePipe <- mkFunnelPipesPipelined(change_pipes, clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   FIFOF#(RegChange) changeFifo <- mkSizedBRAMFIFOF(128, clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   mkConnection(changePipe[0], toPipeIn(changeFifo), clocked_by pcie_ep.user_clk, reset_by user_reset_n);
`else
   let cs <- mkChangeSource(tuple2(Pcie3Cfg_rq_backpressure, extend(rqBackpressureCount)), clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   FIFOF#(RegChange) changeFifo <- mkSizedBRAMFIFOF(128, clocked_by pcie_ep.user_clk, reset_by user_reset_n);
   mkConnection(cs, toPipeIn(changeFifo), clocked_by pcie_ep.user_clk, reset_by user_reset_n);
`endif

   rule rl_drive_cfg_status_if;
      pcie_ep.cfg.config_space_enable(1);
      pcie_ep.cfg.dsn(64'hf001ba7700000000);
      pcie_ep.cfg.ds_bus_number(0);
      pcie_ep.cfg.ds_device_number(0);
      pcie_ep.cfg.ds_port_number(0);
      pcie_ep.cfg.err_cor_in(0);
      pcie_ep.cfg.err_uncor_in(0);
      pcie_ep.cfg.flr_done(0);
      pcie_ep.cfg.hot_reset_in(0);
      pcie_ep.cfg.link_training_enable(1);
      pcie_ep.cfg.per_function_number(0);
      pcie_ep.cfg.per_function_output_request(0);
      pcie_ep.cfg.power_state_change_ack(0);
      pcie_ep.cfg.subsys_vend_id(16'h1be8);
      pcie_ep.cfg.vf_flr_done(0);

      pcie_ep.pcie.cq_np_req(1);

      pcie_ep.cfg_req_pm_transition.l23_ready(0);
   endrule

   // The PCIE endpoint is processing Gen3 descriptors at 250MHz. The
   // AXI bridge is accepting TLPData#(16)s at 250 MHz. The
   // conversion uses half of Gen3 descriptor.
   //mkConnection(tlp8, gb.tlp, clocked_by portalClock, reset_by portalReset);

   let portalClock = (mainClockPeriod == pcieClockPeriod) ? pcieClock250 : mainClock;
   let portalReset = (mainClockPeriod == pcieClockPeriod) ? pcieReset250 : mainReset;

   interface Server tlpr;
      interface request = toPut(frq);
      interface response = toGet(frc);
   endinterface
   // Requests from other PCIe devices
   interface Server tlpc;
      interface request = toPut(fcc);
      interface response = toGet(fcq);
   endinterface
   interface interruptRequest = toPut(intrFifo);
   interface pcie    = pcie_ep.pci_exp;
   interface Pcie3wrapUser user = pcie_ep.user;
   interface PciewrapPipe pipe = pcie_ep.pipe;
   interface PciewrapCommon common= pcie_ep.common;
   interface regChanges = mapPipe(pack, toPipeOut(changeFifo));
   interface Clock epPcieClock = pcieClock250;
   interface Reset epPcieReset = pcieReset250;
   interface Clock epPortalClock = portalClock;
   interface Reset epPortalReset = portalReset;
   interface Clock epDerivedClock = derivedClock;
   interface Reset epDerivedReset = derivedReset;
endmodule: mkPcieEndpointX7

endpackage: Pcie3EndpointX7
