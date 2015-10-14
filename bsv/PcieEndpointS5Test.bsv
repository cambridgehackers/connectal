
// Copyright (c) 2014 Quanta Research Cambridge, Inc.
// Copyright (c) 2014 Cornell Univeristy.

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

import Clocks        ::*;
import Connectable   ::*;
import ConnectalAlteraCells   ::*;

import ALTERA_PCIE_ED_WRAPPER ::*;
import PS5LIB ::*;

`include "ConnectalProjectConfig.bsv"

// Default Pcie Application

(* always_ready, always_enabled *)
interface PcieS5AppRxSt#(numeric type data_width);
   method Action           sop(Bit#(1) sop);
   method Action           eop(Bit#(1) eop);
   method Action           data(Bit#(data_width) data);
   method Action           valid(Bit#(1) valid);
   method Action           empty(Bit#(2) empty);
   method Action           err(Bit#(1) err);
   method Bit#(1)          ready;
endinterface

(* always_ready, always_enabled *)
interface PcieS5AppRxBar;
   method Action           bar(Bit#(8) bar);
   method Bit#(1)          mask;
endinterface

(* always_ready, always_enabled *)
interface PcieS5AppTxSt#(numeric type data_width);
   method Bit#(1)          sop;
   method Bit#(1)          eop;
   method Bit#(1)          valid;
   method Bit#(1)          err;
   method Bit#(2)          empty;
   method Bit#(data_width) data;
   method Action           ready(Bit#(1) ready);
endinterface

(* always_ready, always_enabled *)
interface PcieS5AppTxCred;
   method Action           datafccp(Bit#(12) datafccp);
   method Action           datafcnp(Bit#(12) datafcnp);
   method Action           datafcp(Bit#(12) datafcp);
   method Action           fchipcons(Bit#(6) fchipcons);
   method Action           fcinfinite(Bit#(6) fcinfinite);
   method Action           hdrfccp(Bit#(8) hdrfccp);
   method Action           hdrfcnp(Bit#(8) hdrfcnp);
   method Action           hdrfcp(Bit#(8) hdrfcp);
endinterface

(* always_ready, always_enabled *)
interface PcieS5AppHipRst;
   method Action  serdes_pll_locked(Bit#(1) serdes_pll_locked);
   method Action  pld_clk_inuse(Bit#(1) pld_clk_inuse);
   method Bit#(1) core_ready;
endinterface

(* always_ready, always_enabled *)
interface PcieS5AppMsi;
   method Action      int_ack(Bit#(1) int_ack);
   method Bit#(1)     int_sts();
   method Action      msi_ack(Bit#(1) msi_ack);
   method Bit#(5)     msi_num();
   method Bit#(1)     msi_req();
   method Bit#(3)     msi_tc();
endinterface

(* always_ready, always_enabled *)
interface PcieS5AppHipStatus;
   method Action      cor_ext_rcv(Bit#(1) cor_ext_rcv);
   method Action      cor_ext_rpl(Bit#(1) cor_ext_rpl);
   method Action      rpl        (Bit#(1) rpl);
   method Action      dlup       (Bit#(1) dlup);
   method Action      dlup_exit  (Bit#(1) dlup_exit);
   method Action      ev128ns    (Bit#(1) ev128ns);
   method Action      ev1us      (Bit#(1) ev1us);
   method Action      hotrst     (Bit#(1) hotrstexit);
   method Action      int_status (Bit#(4) int_status);
   method Action      l2_exit    (Bit#(1) l2_exit);
   method Action      lane_act   (Bit#(4) lane_act);
   method Action      ltssmstate (Bit#(5) ltssmstate);
   method Action      rx_par_err (Bit#(1) rx_par_err);
   method Action      tx_par_err (Bit#(2) tx_par_err);
   method Action      cfg_par_err (Bit#(1) cfg_par_err);
   method Action      ko_cpl_spc_data (Bit#(12) ko_cpl_spc_data);
   method Action      ko_cpl_spc_header (Bit#(8) ko_cpl_spc_header);
endinterface

(* always_ready, always_enabled *)
interface PcieS5AppTlCfg;
   method Action      cfg_add(Bit#(4) cfg_add);
   method Action      cfg_ctl(Bit#(32) cfg_ctl);
   method Action      cfg_sts(Bit#(53) cfg_sts);
   method Bit#(1)     cpl_pending;
   method Bit#(7)     cpl_err;
endinterface

(* always_ready, always_enabled *)
interface PcieS5AppLmi;
   method Action      ack(Bit#(1) ack);
   method Bit#(12)    addr();
   method Bit#(32)    din();
   method Action      dout(Bit#(32) dout);
   method Bit#(1)     rden();
   method Bit#(1)     wren();
endinterface

interface PcieS5App;
   interface PcieS5AppRxSt#(128) rx_st;
   interface PcieS5AppRxBar      rx_bar;
   interface PcieS5AppTxSt#(128) tx_st;
   interface PcieS5AppTxCred     tx_cred;
   interface PcieS5AppHipRst     hip_rst;
   interface PcieS5AppMsi        msi;
   interface PcieS5AppHipStatus  hip_status;
   interface PcieS5AppTlCfg      tl;
   interface PcieS5AppLmi        lmi;
endinterface

instance Connectable#(PcieS5App, PcieS5Wrap#(12, 32, 128));
   module mkConnection#(PcieS5App a, PcieS5Wrap#(12, 32, 128) b)(Empty);
      (* fire_when_enabled, no_implicit_conditions *)
      rule rx_st;
         a.rx_st.sop(b.rx_st.sop);
         a.rx_st.eop(b.rx_st.eop);
         a.rx_st.data(b.rx_st.data);
         a.rx_st.valid(b.rx_st.valid);
         a.rx_st.empty(b.rx_st.empty);
         a.rx_st.err(b.rx_st.err);
         b.rx_st.ready(a.rx_st.ready);
      endrule

      rule tx_st;
         b.tx_st.sop(a.tx_st.sop);
         b.tx_st.eop(a.tx_st.eop);
         b.tx_st.data(a.tx_st.data);
         b.tx_st.valid(a.tx_st.valid);
         b.tx_st.empty(a.tx_st.empty);
         b.tx_st.err(a.tx_st.err);
         a.tx_st.ready(b.tx_st.ready);
      endrule

      rule rx_bar;
         a.rx_bar.bar(b.rx_specific.bar);
         b.rx_specific.mask(a.rx_bar.mask);
      endrule

      rule tx_cred;
         a.tx_cred.datafccp(b.tx_cred.datafccp);
         a.tx_cred.datafcnp(b.tx_cred.datafcnp);
         a.tx_cred.datafcp(b.tx_cred.datafcp);
         a.tx_cred.hdrfccp(b.tx_cred.hdrfccp);
         a.tx_cred.hdrfcnp(b.tx_cred.hdrfcnp);
         a.tx_cred.hdrfcp(b.tx_cred.hdrfcp);
         a.tx_cred.fchipcons(b.tx_cred.fchipcons);
         a.tx_cred.fcinfinite(b.tx_cred.fcinfinite);
      endrule

      rule hip_rst;
         a.hip_rst.serdes_pll_locked(b.hip_rst.serdes_pll_locked);
         a.hip_rst.pld_clk_inuse(b.hip_rst.pld_clk_inuse);
         b.hip_rst.core_ready(a.hip_rst.core_ready);
      endrule

      rule msi;
         a.msi.int_ack(b.msi.int_ack);
         a.msi.msi_ack(b.msi.msi_ack);
         b.msi.int_sts(a.msi.int_sts);
         b.msi.msi_num(a.msi.msi_num);
         b.msi.msi_req(a.msi.msi_req);
         b.msi.msi_tc(a.msi.msi_tc);
      endrule

      rule tl;
         a.tl.cfg_add(b.tl.cfg_add);
         a.tl.cfg_ctl(b.tl.cfg_ctl);
         a.tl.cfg_sts(b.tl.cfg_sts);
         b.tl.cpl_pending(a.tl.cpl_pending);
         b.tl.cpl_err(a.tl.cpl_err);
      endrule

      rule lmi;
         a.lmi.ack(b.lmi.ack);
         a.lmi.dout(b.lmi.dout);
         b.lmi.addr(a.lmi.addr);
         b.lmi.din(a.lmi.din);
         b.lmi.rden(a.lmi.rden);
         b.lmi.wren(a.lmi.wren);
      endrule

      rule hipstatus;
         a.hip_status.cor_ext_rcv(b.hip_status.cor_ext_rcv);
         a.hip_status.cor_ext_rpl(b.hip_status.cor_ext_rpl);
         a.hip_status.rpl(b.hip_status.rpl);
         a.hip_status.dlup(b.hip_status.dlup);
         a.hip_status.dlup_exit(b.hip_status.dlup_exit);
         a.hip_status.ev128ns(b.hip_status.ev128ns);
         a.hip_status.ev1us(b.hip_status.ev1us);
         a.hip_status.hotrst(b.hip_status.hotrst);
         a.hip_status.int_status(b.hip_status.int_status);
         a.hip_status.l2_exit(b.hip_status.l2_exit);
         a.hip_status.lane_act(b.hip_status.lane_act);
         a.hip_status.ltssmstate(b.hip_status.ltssmstate);
         a.hip_status.rx_par_err(b.hip_status.rx_par_err);
         a.hip_status.tx_par_err(b.hip_status.tx_par_err);
         a.hip_status.cfg_par_err(b.hip_status.cfg_par_err);
         a.hip_status.ko_cpl_spc_data(b.hip_status.ko_cpl_spc_data);
         a.hip_status.ko_cpl_spc_header(b.hip_status.ko_cpl_spc_header);
      endrule
   endmodule
endinstance

module mkPcieS5App#(Clock core_clk, Reset core_clk_rst) (PcieS5App);

   PcieEdWrap pcie_app <- mkPcieEdWrap(core_clk, core_clk_rst);

   rule every1;
      pcie_app.testin.zero(0);
      pcie_app.pme.to_sr(0);
      pcie_app.reset.status(0);
      pcie_app.rx_s.t_be(16'hFFFF); // rx_st.be is deprecated.
   endrule

   interface PcieS5AppRxSt rx_st;
      method sop   = pcie_app.rx_s.t_sop;
      method eop   = pcie_app.rx_s.t_eop;
      method data  = pcie_app.rx_s.t_data;
      method valid = pcie_app.rx_s.t_valid;
      method empty = pcie_app.rx_s.t_empty;
      method err   = pcie_app.rx_s.t_err;
      method Bit#(1) ready; return pcie_app.rx_s.t_ready; endmethod
   endinterface

   interface PcieS5AppRxBar rx_bar;
      method bar = pcie_app.rx_s.t_bar;
      method Bit#(1) mask; return pcie_app.rx_s.t_mask; endmethod
   endinterface

   interface PcieS5AppTxSt tx_st;
      method Bit#(1) sop;   return pcie_app.tx_s.t_sop;   endmethod
      method Bit#(1) eop;   return pcie_app.tx_s.t_eop;   endmethod
      method Bit#(1) valid; return pcie_app.tx_s.t_valid; endmethod
      method Bit#(1) err;   return pcie_app.tx_s.t_err;   endmethod
      method Bit#(2) empty; return pcie_app.tx_s.t_empty; endmethod
      method Bit#(128) data; return pcie_app.tx_s.t_data;  endmethod
      method ready = pcie_app.tx_s.t_ready;
   endinterface

   interface PcieS5AppTxCred tx_cred;
      method datafccp   = pcie_app.tx_cred.datafccp;
      method datafcnp   = pcie_app.tx_cred.datafcnp;
      method datafcp    = pcie_app.tx_cred.datafcp;
      method fchipcons  = pcie_app.tx_cred.fchipcons;
      method fcinfinite = pcie_app.tx_cred.fcinfinite;
      method hdrfccp    = pcie_app.tx_cred.hdrfccp;
      method hdrfcnp    = pcie_app.tx_cred.hdrfcnp;
      method hdrfcp     = pcie_app.tx_cred.hdrfcp;
   endinterface

   interface PcieS5AppHipRst hip_rst;
      method serdes_pll_locked = pcie_app.serdes.pll_locked;
      method pld_clk_inuse = pcie_app.pld.clk_inuse;
      method Bit#(1) core_ready;
         return pcie_app.pld.core_ready;
      endmethod
   endinterface

   interface PcieS5AppMsi msi;
      method Bit#(1) int_sts;  return pcie_app.app.int_sts;  endmethod
      method Bit#(5) msi_num;  return pcie_app.app.msi_num;  endmethod
      method Bit#(1) msi_req;  return pcie_app.app.msi_req;  endmethod
      method Bit#(3) msi_tc;   return pcie_app.app.msi_tc;   endmethod
      method int_ack = pcie_app.app.int_ack;
      method msi_ack = pcie_app.app.msi_ack;
   endinterface

   interface PcieS5AppHipStatus hip_status;
      method cor_ext_rcv = pcie_app.derr.cor_ext_rcv;
      method cor_ext_rpl = pcie_app.derr.cor_ext_rpl;
      method rpl         = pcie_app.derr.rpl;
      method dlup        = pcie_app.dl.up;
      method dlup_exit   = pcie_app.dl.up_exit;
      method ev128ns     = pcie_app.ev128.ns;
      method ev1us       = pcie_app.ev1.us;
      method hotrst      = pcie_app.hotrst.exit;
      method int_status  = pcie_app.int_s.tatus;
      method l2_exit     = pcie_app.l2.exit;
      method lane_act    = pcie_app.lane.act;
      method ltssmstate  = pcie_app.ltssm.state;
      method rx_par_err  = pcie_app.rx_par.err;
      method tx_par_err  = pcie_app.tx_par.err;
      method cfg_par_err  = pcie_app.cfg_par.err;
      method ko_cpl_spc_data = pcie_app.ko.cpl_spc_data;
      method ko_cpl_spc_header = pcie_app.ko.cpl_spc_header;
   endinterface

   interface PcieS5AppTlCfg tl;
      method cfg_add = pcie_app.tl.cfg_add;
      method cfg_ctl = pcie_app.tl.cfg_ctl;
      method cfg_sts = pcie_app.tl.cfg_sts;
      method cpl_pending; return pcie_app.cpl.pending; endmethod
      method cpl_err;     return pcie_app.cpl.err;     endmethod
   endinterface

   interface PcieS5AppLmi lmi;
      method Bit#(12) addr;  return pcie_app.lmi.addr;  endmethod
      method Bit#(32) din;   return pcie_app.lmi.din;   endmethod
      method Bit#(1)  rden;  return pcie_app.lmi.rden;  endmethod
      method Bit#(1)  wren;  return pcie_app.lmi.wren;  endmethod
      method ack = pcie_app.lmi.ack;
      method dout = pcie_app.lmi.dout;
   endinterface
endmodule

`ifdef PCIES5_SIM
// PcieS5Top
// Used for simulation with Default Pcie Application
(* always_ready, always_enabled *)
interface PcieS5Top;
   interface PcieS5HipSerial hip_serial;
   interface PcieS5HipPipe hip_pipe;
   interface PcieS5HipCtrl hip_ctrl;
endinterface

(* synthesize, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkPcieS5Top #(Clock clk_50_clk, Clock clk_100_clk, Reset clk_50_rst_reset_n, Reset rst_n_npor, Reset rst_n_pin_perst) (PcieS5Top);

   PcieS5Wrap#(12, 32, 128) pcie <- mkPcieS5Wrap(clk_100_clk, clk_50_clk, rst_n_npor, rst_n_pin_perst, clk_50_rst_reset_n, clocked_by clk_100_clk, reset_by clk_50_rst_reset_n);

   Clock coreclk = pcie.coreclkout_hip;
   PcieS5App pcie_app <- mkPcieS5App(coreclk, clk_50_rst_reset_n, clocked_by clk_100_clk, reset_by clk_50_rst_reset_n);

   mkConnection(pcie_app, pcie);

   interface PcieS5HipSerial hip_serial;
      interface rx = pcie.rx;
      interface tx = pcie.tx;
   endinterface

   interface PcieS5HipPipe hip_pipe = pcie.hip_pipe;
   interface PcieS5HipCtrl hip_ctrl = pcie.hip_ctrl;
endmodule
`endif
