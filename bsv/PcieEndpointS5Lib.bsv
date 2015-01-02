
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
import Vector        ::*;
import Connectable   ::*;
import ConnectalAlteraCells ::*;

import ALTERA_XCVR_RECONFIG_WRAPPER        ::*;
import ALTERA_PCIE_RECONFIG_DRIVER_WRAPPER ::*;
import ALTERA_PCIE_WRAPPER                 ::*;

(* always_ready, always_enabled *)
interface PcieS5Lmi#(numeric type address_width, numeric type data_width);
   method Action           rden(Bit#(1) rden);
   method Action           wren(Bit#(1) wren);
   method Action           addr(Bit#(address_width) addr);
   method Action           din(Bit#(data_width) din);
   method Bit#(data_width) dout();
   method Bit#(1)          ack();
endinterface

(* always_ready, always_enabled *)
interface PcieS5RxSt#(numeric type data_width);
   method Bit#(1)          sop;
   method Bit#(1)          eop;
   method Bit#(data_width) data;
   method Bit#(16)         be;
   method Action           ready(Bit#(1) ready);
   method Bit#(1)          valid;
   method Bit#(1)          err;
   method Bit#(2)          empty;
endinterface

(* always_ready, always_enabled *)
interface PcieS5TxSt#(numeric type data_width);
   method Action           sop(Bit#(1) sop);
   method Action           eop(Bit#(1) eop);
   method Action           valid(Bit#(1) valid);
   method Action           err(Bit#(1) err);
   method Action           empty(Bit#(2) empty);
   method Bit#(1)          ready;
   method Action           data(Bit#(data_width) data);
endinterface

(* always_ready, always_enabled *)
interface PcieS5Msi;
   method Bit#(1)  int_ack();
   method Action   int_sts (Bit#(1) int_sts);
   method Bit#(1)  msi_ack();
   method Action   msi_num(Bit#(5)num);
   method Action   msi_req(Bit#(1)req);
   method Action   msi_tc(Bit#(3)tc);
endinterface

(* always_ready, always_enabled *)
interface PcieS5RxBar;
   method Action   mask(Bit#(1) mask);
   method Bit#(8)  bar();
endinterface

(* always_ready, always_enabled *)
interface PcieS5TlCfg;
   method Bit#(4)  cfg_add();
   method Bit#(32) cfg_ctl();
   method Bit#(53) cfg_sts();
   method Action   cpl_pending(Bit#(1) cpl_pending);
   method Action   cpl_err(Bit#(7) cpl_err);
endinterface

(* always_ready, always_enabled *)
interface PcieS5HipRst;
   method Bit#(1) serdes_pll_locked();
   method Bit#(1) pld_clk_inuse();
   method Action  core_ready(Bit#(1) core_ready);
endinterface

(* always_ready, always_enabled *)
interface PcieS5TxCred;
   method Bit#(12) datafccp();
   method Bit#(12) datafcnp();
   method Bit#(12) datafcp();
   method Bit#(8)  hdrfccp();
   method Bit#(8)  hdrfcnp();
   method Bit#(8)  hdrfcp();
   method Bit#(6)  fchipcons();
   method Bit#(6)  fcinfinite();
endinterface

(* always_ready, always_enabled *)
interface PcieS5Rxin;
(* prefix="", result="in0" *)   method Action in0(Bit#(1)in0);
(* prefix="", result="in1" *)   method Action in1(Bit#(1)in1);
(* prefix="", result="in2" *)   method Action in2(Bit#(1)in2);
(* prefix="", result="in3" *)   method Action in3(Bit#(1)in3);
(* prefix="", result="in4" *)   method Action in4(Bit#(1)in4);
(* prefix="", result="in5" *)   method Action in5(Bit#(1)in5);
(* prefix="", result="in6" *)   method Action in6(Bit#(1)in6);
(* prefix="", result="in7" *)   method Action in7(Bit#(1)in7);
endinterface

(* always_ready, always_enabled *)
interface PcieS5Txout;
   method Bit#(1) out0();
   method Bit#(1) out1();
   method Bit#(1) out2();
   method Bit#(1) out3();
   method Bit#(1) out4();
   method Bit#(1) out5();
   method Bit#(1) out6();
   method Bit#(1) out7();
endinterface

(* always_ready, always_enabled *)
interface PcieS5HipStatus;
   method Bit#(1) cor_ext_rcv;
   method Bit#(1) cor_ext_rpl;
   method Bit#(1) rpl;
   method Bit#(1) dlup;
   method Bit#(1) dlup_exit;
   method Bit#(1) ev128ns;
   method Bit#(1) ev1us;
   method Bit#(1) hotrst;
   method Bit#(4) int_status;
   method Bit#(1) l2_exit;
   method Bit#(4) lane_act;
   method Bit#(5) ltssmstate;
   method Bit#(1) rx_par_err;
   method Bit#(2) tx_par_err;
 (* prefix="", result="cfg_par_err" *)  method Bit#(1) cfg_par_err;
   method Bit#(12) ko_cpl_spc_data;
   method Bit#(8) ko_cpl_spc_header;
endinterface

interface PcieS5HipSerial;
   interface PcieS5Rxin rx;
   interface PcieS5Txout tx;
endinterface

`ifdef PCIES5_SIM
interface PcieS5HipPipe;
(* prefix="", result="rxdata0" *)     method Action     rxdata0(Bit#(8) rxdata0);
(* prefix="", result="rxdata1" *)     method Action     rxdata1(Bit#(8) rxdata1);
(* prefix="", result="rxdata2" *)     method Action     rxdata2(Bit#(8) rxdata2);
(* prefix="", result="rxdata3" *)     method Action     rxdata3(Bit#(8) rxdata3);
(* prefix="", result="rxdata4" *)     method Action     rxdata4(Bit#(8) rxdata4);
(* prefix="", result="rxdata5" *)     method Action     rxdata5(Bit#(8) rxdata5);
(* prefix="", result="rxdata6" *)     method Action     rxdata6(Bit#(8) rxdata6);
(* prefix="", result="rxdata7" *)     method Action     rxdata7(Bit#(8) rxdata7);
(* prefix="", result="rxdatak0" *)    method Action     rxdatak0(Bit#(1) rxdatak0);
(* prefix="", result="rxdatak1" *)    method Action     rxdatak1(Bit#(1) rxdatak1);
(* prefix="", result="rxdatak2" *)    method Action     rxdatak2(Bit#(1) rxdatak2);
(* prefix="", result="rxdatak3" *)    method Action     rxdatak3(Bit#(1) rxdatak3);
(* prefix="", result="rxdatak4" *)    method Action     rxdatak4(Bit#(1) rxdatak4);
(* prefix="", result="rxdatak5" *)    method Action     rxdatak5(Bit#(1) rxdatak5);
(* prefix="", result="rxdatak6" *)    method Action     rxdatak6(Bit#(1) rxdatak6);
(* prefix="", result="rxdatak7" *)    method Action     rxdatak7(Bit#(1) rxdatak7);
(* prefix="", result="rxelecidle0" *) method Action     rxelecidle0(Bit#(1) rxelecidle0);
(* prefix="", result="rxelecidle1" *) method Action     rxelecidle1(Bit#(1) rxelecidle1);
(* prefix="", result="rxelecidle2" *) method Action     rxelecidle2(Bit#(1) rxelecidle2);
(* prefix="", result="rxelecidle3" *) method Action     rxelecidle3(Bit#(1) rxelecidle3);
(* prefix="", result="rxelecidle4" *) method Action     rxelecidle4(Bit#(1) rxelecidle4);
(* prefix="", result="rxelecidle5" *) method Action     rxelecidle5(Bit#(1) rxelecidle5);
(* prefix="", result="rxelecidle6" *) method Action     rxelecidle6(Bit#(1) rxelecidle6);
(* prefix="", result="rxelecidle7" *) method Action     rxelecidle7(Bit#(1) rxelecidle7);
    method Bit#(1)    rxpolarity0();
    method Bit#(1)    rxpolarity1();
    method Bit#(1)    rxpolarity2();
    method Bit#(1)    rxpolarity3();
    method Bit#(1)    rxpolarity4();
    method Bit#(1)    rxpolarity5();
    method Bit#(1)    rxpolarity6();
    method Bit#(1)    rxpolarity7();
(* prefix="", result="rxstatus0" *)   method Action     rxstatus0(Bit#(3) rxstatus0);
(* prefix="", result="rxstatus1" *)   method Action     rxstatus1(Bit#(3) rxstatus1);
(* prefix="", result="rxstatus2" *)   method Action     rxstatus2(Bit#(3) rxstatus2);
(* prefix="", result="rxstatus3" *)   method Action     rxstatus3(Bit#(3) rxstatus3);
(* prefix="", result="rxstatus4" *)   method Action     rxstatus4(Bit#(3) rxstatus4);
(* prefix="", result="rxstatus5" *)   method Action     rxstatus5(Bit#(3) rxstatus5);
(* prefix="", result="rxstatus6" *)   method Action     rxstatus6(Bit#(3) rxstatus6);
(* prefix="", result="rxstatus7" *)   method Action     rxstatus7(Bit#(3) rxstatus7);
(* prefix="", result="rxvalid0" *)    method Action     rxvalid0(Bit#(1) rxvalid0);
(* prefix="", result="rxvalid1" *)    method Action     rxvalid1(Bit#(1) rxvalid1);
(* prefix="", result="rxvalid2" *)    method Action     rxvalid2(Bit#(1) rxvalid2);
(* prefix="", result="rxvalid3" *)    method Action     rxvalid3(Bit#(1) rxvalid3);
(* prefix="", result="rxvalid4" *)    method Action     rxvalid4(Bit#(1) rxvalid4);
(* prefix="", result="rxvalid5" *)    method Action     rxvalid5(Bit#(1) rxvalid5);
(* prefix="", result="rxvalid6" *)    method Action     rxvalid6(Bit#(1) rxvalid6);
(* prefix="", result="rxvalid7" *)    method Action     rxvalid7(Bit#(1) rxvalid7);
    method Bit#(1)    txcompl0();
    method Bit#(1)    txcompl1();
    method Bit#(1)    txcompl2();
    method Bit#(1)    txcompl3();
    method Bit#(1)    txcompl4();
    method Bit#(1)    txcompl5();
    method Bit#(1)    txcompl6();
    method Bit#(1)    txcompl7();
    method Bit#(8)    txdata0();
    method Bit#(8)    txdata1();
    method Bit#(8)    txdata2();
    method Bit#(8)    txdata3();
    method Bit#(8)    txdata4();
    method Bit#(8)    txdata5();
    method Bit#(8)    txdata6();
    method Bit#(8)    txdata7();
    method Bit#(1)    txdatak0();
    method Bit#(1)    txdatak1();
    method Bit#(1)    txdatak2();
    method Bit#(1)    txdatak3();
    method Bit#(1)    txdatak4();
    method Bit#(1)    txdatak5();
    method Bit#(1)    txdatak6();
    method Bit#(1)    txdatak7();
    method Bit#(1)    txdeemph0();
    method Bit#(1)    txdeemph1();
    method Bit#(1)    txdeemph2();
    method Bit#(1)    txdeemph3();
    method Bit#(1)    txdeemph4();
    method Bit#(1)    txdeemph5();
    method Bit#(1)    txdeemph6();
    method Bit#(1)    txdeemph7();
    method Bit#(1)    txdetectrx0();
    method Bit#(1)    txdetectrx1();
    method Bit#(1)    txdetectrx2();
    method Bit#(1)    txdetectrx3();
    method Bit#(1)    txdetectrx4();
    method Bit#(1)    txdetectrx5();
    method Bit#(1)    txdetectrx6();
    method Bit#(1)    txdetectrx7();
    method Bit#(1)    txelecidle0();
    method Bit#(1)    txelecidle1();
    method Bit#(1)    txelecidle2();
    method Bit#(1)    txelecidle3();
    method Bit#(1)    txelecidle4();
    method Bit#(1)    txelecidle5();
    method Bit#(1)    txelecidle6();
    method Bit#(1)    txelecidle7();
    method Bit#(3)    txmargin0();
    method Bit#(3)    txmargin1();
    method Bit#(3)    txmargin2();
    method Bit#(3)    txmargin3();
    method Bit#(3)    txmargin4();
    method Bit#(3)    txmargin5();
    method Bit#(3)    txmargin6();
    method Bit#(3)    txmargin7();
    method Bit#(1)    txswing0();
    method Bit#(1)    txswing1();
    method Bit#(1)    txswing2();
    method Bit#(1)    txswing3();
    method Bit#(1)    txswing4();
    method Bit#(1)    txswing5();
    method Bit#(1)    txswing6();
    method Bit#(1)    txswing7();
    method Bit#(2)    powerdown0();
    method Bit#(2)    powerdown1();
    method Bit#(2)    powerdown2();
    method Bit#(2)    powerdown3();
    method Bit#(2)    powerdown4();
    method Bit#(2)    powerdown5();
    method Bit#(2)    powerdown6();
    method Bit#(2)    powerdown7();
(* prefix="", result="phystatus0" *) method Action     phystatus0(Bit#(1)phystatus0);
(* prefix="", result="phystatus1" *) method Action     phystatus1(Bit#(1)phystatus1);
(* prefix="", result="phystatus2" *) method Action     phystatus2(Bit#(1)phystatus2);
(* prefix="", result="phystatus3" *) method Action     phystatus3(Bit#(1)phystatus3);
(* prefix="", result="phystatus4" *) method Action     phystatus4(Bit#(1)phystatus4);
(* prefix="", result="phystatus5" *) method Action     phystatus5(Bit#(1)phystatus5);
(* prefix="", result="phystatus6" *) method Action     phystatus6(Bit#(1)phystatus6);
(* prefix="", result="phystatus7" *) method Action     phystatus7(Bit#(1)phystatus7);
    method Bit#(3)    eidleinfersel0();
    method Bit#(3)    eidleinfersel1();
    method Bit#(3)    eidleinfersel2();
    method Bit#(3)    eidleinfersel3();
    method Bit#(3)    eidleinfersel4();
    method Bit#(3)    eidleinfersel5();
    method Bit#(3)    eidleinfersel6();
    method Bit#(3)    eidleinfersel7();
    method Bit#(5)    sim_ltssmstate();
(* prefix="", result="sim_pipe_pclk_in" *) method Action sim_pipe_pclk_in(Bit#(1) sim_pipe_pclk_in);
    method Bit#(2)    sim_pipe_rate();
endinterface
`endif

(* always_ready, always_enabled *)
interface PcieS5HipCtrl;
(* prefix="", result="test_in" *)        method Action test_in(Bit#(32) test_in);
(* prefix="", result="simu_mode_pipe" *) method Action simu_mode_pipe(Bit#(1) simu_mode_pipe);
endinterface

(* always_ready, always_enabled *)
interface PcieS5Wrap#(numeric type address_width, numeric type data_width, numeric type app_width);
   interface PcieS5Lmi#(address_width, data_width) lmi;
   interface PcieS5RxSt#(app_width) rx_st;
   interface PcieS5TxSt#(app_width) tx_st;
   interface PcieS5Msi msi;
   interface PcieS5RxBar rx_bar;
   interface PcieS5TlCfg tl;
   interface PcieS5HipRst hip_rst;
   interface PcieS5TxCred tx_cred;
   interface PcieS5Rxin rx;
   interface PcieS5Txout tx;
   interface PcieS5HipStatus hip_status;
`ifdef PCIES5_SIM
   interface PcieS5HipPipe hip_pipe;
`endif
   interface PcieS5HipCtrl hip_ctrl;
   interface Clock coreclkout_hip;
endinterface

(* synthesize *)
module mkPcieS5Wrap#(Clock clk_100Mhz, Clock clk_50Mhz, Reset npor, Reset pin_perst, Reset clk_50_rst_n)(PcieS5Wrap#(12, 32, 128));

   PcieWrap         pcie     <- mkPcieWrap(clk_100Mhz, npor, pin_perst, clk_50_rst_n);

   Clock coreclk = pcie.coreclkout.hip;
   PcieReconfigWrap pcie_cfg <- mkPcieReconfigWrap(coreclk, clk_50Mhz, clk_50_rst_n, clk_50_rst_n, clk_50_rst_n);
   XcvrReconfigWrap xcvr_cfg <- mkXcvrReconfigWrap(clk_50Mhz, clk_50_rst_n, clk_50_rst_n);

   (* no_implicit_conditions *)
   rule connectReconfigMgmt;
      xcvr_cfg.reconfig_mgmt.read(pcie_cfg.reconfig_mgmt.read);
      xcvr_cfg.reconfig_mgmt.write(pcie_cfg.reconfig_mgmt.write);
      xcvr_cfg.reconfig_mgmt.address(pcie_cfg.reconfig_mgmt.address);
      xcvr_cfg.reconfig_mgmt.writedata(pcie_cfg.reconfig_mgmt.writedata);
      pcie_cfg.reconfig_mgmt.readdata(xcvr_cfg.reconfig_mgmt.readdata);
      pcie_cfg.reconfig_mgmt.waitrequest(xcvr_cfg.reconfig_mgmt.waitrequest);
   endrule

   (* no_implicit_conditions *)
   rule connectCurrentSpeed;
      pcie_cfg.current.speed(pcie.current.speed);
   endrule

   (* no_implicit_conditions *)
   rule connect_xcvr_reconfig;
      pcie.reconfig.to_xcvr(xcvr_cfg.reconfig.to_xcvr);
      xcvr_cfg.reconfig.from_xcvr(pcie.reconfig.from_xcvr);
   endrule

   (* no_implicit_conditions *)
   rule connectBusy;
      pcie_cfg.reconfig_b.usy(xcvr_cfg.reconfig.busy);
   endrule

   (* no_implicit_conditions *)
   rule connectHipStatus;
      pcie_cfg.derr.cor_ext_rcv_drv(pcie.derr.cor_ext_rcv);
      pcie_cfg.derr.cor_ext_rpl_drv(pcie.derr.cor_ext_rpl);
      pcie_cfg.derr.rpl_drv(pcie.derr.rpl);
      pcie_cfg.dlup.drv(pcie.dl.up);
      pcie_cfg.dlup.exit_drv(pcie.dl.up_exit);
      pcie_cfg.ev128ns.drv(pcie.ev128.ns);
      pcie_cfg.ev1us.drv(pcie.ev1.us);
      pcie_cfg.hotrst.exit_drv(pcie.hotrst.exit);
      pcie_cfg.int_s.tatus_drv(pcie.int_s.tatus);
      pcie_cfg.lane.act_drv(pcie.lane.act);
      pcie_cfg.l2.exit_drv(pcie.l2.exit);
      pcie_cfg.ltssmstate.drv(pcie.ltssm.state);
      pcie_cfg.tx.par_err_drv(pcie.tx_par.err);
      pcie_cfg.rx.par_err_drv(pcie.rx_par.err);
      pcie_cfg.cfg.par_err_drv(pcie.cfg_par.err);
      pcie_cfg.ko.cpl_spc_data_drv(pcie.ko.cpl_spc_data);
      pcie_cfg.ko.cpl_spc_header_drv(pcie.ko.cpl_spc_header);
   endrule

   (* no_implicit_conditions *)
   rule power_mgmt;
      pcie.pm.auxpwr(0);
      pcie.pm.data(10'b0);
      pcie.pm_e.vent(0);
      pcie.pme.to_cr(0);
      pcie.hpg.ctrler(5'b0);
   endrule

   C2B c2b <- mkC2B(pcie.coreclkout.hip);
   rule pld_clk_rule;
      pcie.pld.clk(c2b.o());
   endrule

   method Clock coreclkout_hip;
      return pcie.coreclkout.hip;
   endmethod

   interface PcieS5TlCfg tl;
      method Bit#(4) cfg_add();
         return pcie.tl.cfg_add;
      endmethod
      method Bit#(32) cfg_ctl();
         return pcie.tl.cfg_ctl;
      endmethod
      method Bit#(53) cfg_sts();
         return pcie.tl.cfg_sts;
      endmethod
      method cpl_pending = pcie.cpl.pending;
      method cpl_err = pcie.cpl.err;
   endinterface

   interface PcieS5Lmi lmi;
      method Bit#(32) dout();
         return pcie.lmi.dout;
      endmethod

      method Bit#(1) ack ();
         return pcie.lmi.ack;
      endmethod

      method rden = pcie.lmi.rden;
      method wren = pcie.lmi.wren;
      method addr = pcie.lmi.addr;
      method din = pcie.lmi.din;
   endinterface

   interface PcieS5RxSt rx_st;
      method Bit#(1)   sop();   return pcie.rx_s.t_sop;   endmethod
      method Bit#(1)   eop();   return pcie.rx_s.t_eop;   endmethod
      method Bit#(128) data();  return pcie.rx_s.t_data;  endmethod
      method Bit#(16)  be();    return pcie.rx_s.t_be;    endmethod
      method Bit#(1)   valid(); return pcie.rx_s.t_valid; endmethod
      method Bit#(1)   err();   return pcie.rx_s.t_err;   endmethod
      method Bit#(2)   empty(); return pcie.rx_s.t_empty; endmethod
      method ready = pcie.rx_s.t_ready;
   endinterface

   interface PcieS5TxSt tx_st;
      method Bit#(1) ready (); return pcie.tx_s.t_ready; endmethod
      method sop   = pcie.tx_s.t_sop;
      method eop   = pcie.tx_s.t_eop;
      method valid = pcie.tx_s.t_valid;
      method err   = pcie.tx_s.t_err;
      method empty = pcie.tx_s.t_empty;
      method data  = pcie.tx_s.t_data;
   endinterface

   interface PcieS5Msi msi;
      method Bit#(1) int_ack(); return pcie.app.int_ack; endmethod
      method Bit#(1) msi_ack(); return pcie.app.msi_ack; endmethod

      method int_sts = pcie.app.int_sts;
      method msi_num = pcie.app.msi_num;
      method msi_req = pcie.app.msi_req;
      method msi_tc = pcie.app.msi_tc;
   endinterface

   interface PcieS5RxBar rx_bar;
      method mask = pcie.rx_s.t_mask;
      method Bit#(8) bar (); return pcie.rx_s.t_bar; endmethod
   endinterface

   interface PcieS5HipRst hip_rst;
      method Bit#(1) serdes_pll_locked(); return pcie.serdes.pll_locked; endmethod
      method Bit#(1) pld_clk_inuse(); return pcie.pld.clk_inuse; endmethod
      method core_ready = pcie.pld.core_ready;
   endinterface

   interface PcieS5TxCred tx_cred;
      method Bit#(12) datafccp(); return pcie.tx_cred.datafccp; endmethod
      method Bit#(12) datafcnp(); return pcie.tx_cred.datafcnp; endmethod
      method Bit#(12) datafcp();  return pcie.tx_cred.datafcp;  endmethod
      method Bit#(8) hdrfccp();   return pcie.tx_cred.hdrfccp;  endmethod
      method Bit#(8) hdrfcnp();   return pcie.tx_cred.hdrfcnp;  endmethod
      method Bit#(8) hdrfcp();    return pcie.tx_cred.hdrfcp;   endmethod
      method Bit#(6) fchipcons(); return pcie.tx_cred.fchipcons; endmethod
      method Bit#(6) fcinfinite();return pcie.tx_cred.fcinfinite;endmethod
   endinterface

   interface PcieS5Rxin rx;
      method in0 = pcie.rx.in0;
      method in1 = pcie.rx.in1;
      method in2 = pcie.rx.in2;
      method in3 = pcie.rx.in3;
      method in4 = pcie.rx.in4;
      method in5 = pcie.rx.in5;
      method in6 = pcie.rx.in6;
      method in7 = pcie.rx.in7;
   endinterface

   interface PcieS5Txout tx;
      method Bit#(1) out0(); return pcie.tx.out0; endmethod
      method Bit#(1) out1(); return pcie.tx.out1; endmethod
      method Bit#(1) out2(); return pcie.tx.out2; endmethod
      method Bit#(1) out3(); return pcie.tx.out3; endmethod
      method Bit#(1) out4(); return pcie.tx.out4; endmethod
      method Bit#(1) out5(); return pcie.tx.out5; endmethod
      method Bit#(1) out6(); return pcie.tx.out6; endmethod
      method Bit#(1) out7(); return pcie.tx.out7; endmethod
   endinterface

   interface PcieS5HipStatus hip_status;
      method Bit#(1) cor_ext_rcv; return pcie.derr.cor_ext_rcv; endmethod
      method Bit#(1) cor_ext_rpl; return pcie.derr.cor_ext_rpl; endmethod
      method Bit#(1) rpl;         return pcie.derr.rpl;         endmethod
      method Bit#(1) dlup;        return pcie.dl.up;            endmethod
      method Bit#(1) dlup_exit;   return pcie.dl.up_exit;       endmethod
      method Bit#(1) ev128ns;     return pcie.ev128.ns;         endmethod
      method Bit#(1) ev1us;       return pcie.ev1.us;           endmethod
      method Bit#(1) hotrst;      return pcie.hotrst.exit;      endmethod
      method Bit#(4) int_status;  return pcie.int_s.tatus;      endmethod
      method Bit#(1) l2_exit;     return pcie.l2.exit;          endmethod
      method Bit#(4) lane_act;    return pcie.lane.act;         endmethod
      method Bit#(5) ltssmstate;  return pcie.ltssm.state;      endmethod
      method Bit#(1) rx_par_err;  return pcie.rx_par.err;       endmethod
      method Bit#(2) tx_par_err;  return pcie.tx_par.err;       endmethod
      method Bit#(1) cfg_par_err; return pcie.cfg_par.err;      endmethod
      method Bit#(12) ko_cpl_spc_data; return pcie.ko.cpl_spc_data; endmethod
      method Bit#(8) ko_cpl_spc_header;return pcie.ko.cpl_spc_header;endmethod
   endinterface

`ifdef PCIES5_SIM
   interface PcieS5HipPipe hip_pipe;
      method rxdata0 = pcie.rxd.ata0;
      method rxdata1 = pcie.rxd.ata1;
      method rxdata2 = pcie.rxd.ata2;
      method rxdata3 = pcie.rxd.ata3;
      method rxdata4 = pcie.rxd.ata4;
      method rxdata5 = pcie.rxd.ata5;
      method rxdata6 = pcie.rxd.ata6;
      method rxdata7 = pcie.rxd.ata7;
      method rxdatak0 = pcie.rxd.atak0;
      method rxdatak1 = pcie.rxd.atak1;
      method rxdatak2 = pcie.rxd.atak2;
      method rxdatak3 = pcie.rxd.atak3;
      method rxdatak4 = pcie.rxd.atak4;
      method rxdatak5 = pcie.rxd.atak5;
      method rxdatak6 = pcie.rxd.atak6;
      method rxdatak7 = pcie.rxd.atak7;
      method rxelecidle0 = pcie.rxe.lecidle0;
      method rxelecidle1 = pcie.rxe.lecidle1;
      method rxelecidle2 = pcie.rxe.lecidle2;
      method rxelecidle3 = pcie.rxe.lecidle3;
      method rxelecidle4 = pcie.rxe.lecidle4;
      method rxelecidle5 = pcie.rxe.lecidle5;
      method rxelecidle6 = pcie.rxe.lecidle6;
      method rxelecidle7 = pcie.rxe.lecidle7;
      method rxpolarity0(); return pcie.rxp.olarity0; endmethod
      method rxpolarity1(); return pcie.rxp.olarity1; endmethod
      method rxpolarity2(); return pcie.rxp.olarity2; endmethod
      method rxpolarity3(); return pcie.rxp.olarity3; endmethod
      method rxpolarity4(); return pcie.rxp.olarity4; endmethod
      method rxpolarity5(); return pcie.rxp.olarity5; endmethod
      method rxpolarity6(); return pcie.rxp.olarity6; endmethod
      method rxpolarity7(); return pcie.rxp.olarity7; endmethod
      method rxstatus0 = pcie.rxs.tatus0;
      method rxstatus1 = pcie.rxs.tatus1;
      method rxstatus2 = pcie.rxs.tatus2;
      method rxstatus3 = pcie.rxs.tatus3;
      method rxstatus4 = pcie.rxs.tatus4;
      method rxstatus5 = pcie.rxs.tatus5;
      method rxstatus6 = pcie.rxs.tatus6;
      method rxstatus7 = pcie.rxs.tatus7;
      method rxvalid0 = pcie.rxv.alid0;
      method rxvalid1 = pcie.rxv.alid1;
      method rxvalid2 = pcie.rxv.alid2;
      method rxvalid3 = pcie.rxv.alid3;
      method rxvalid4 = pcie.rxv.alid4;
      method rxvalid5 = pcie.rxv.alid5;
      method rxvalid6 = pcie.rxv.alid6;
      method rxvalid7 = pcie.rxv.alid7;
      method txcompl0(); return pcie.txc.ompl0; endmethod
      method txcompl1(); return pcie.txc.ompl1; endmethod
      method txcompl2(); return pcie.txc.ompl2; endmethod
      method txcompl3(); return pcie.txc.ompl3; endmethod
      method txcompl4(); return pcie.txc.ompl4; endmethod
      method txcompl5(); return pcie.txc.ompl5; endmethod
      method txcompl6(); return pcie.txc.ompl6; endmethod
      method txcompl7(); return pcie.txc.ompl7; endmethod
      method txdata0(); return pcie.txd.ata0; endmethod
      method txdata1(); return pcie.txd.ata1; endmethod
      method txdata2(); return pcie.txd.ata2; endmethod
      method txdata3(); return pcie.txd.ata3; endmethod
      method txdata4(); return pcie.txd.ata4; endmethod
      method txdata5(); return pcie.txd.ata5; endmethod
      method txdata6(); return pcie.txd.ata6; endmethod
      method txdata7(); return pcie.txd.ata7; endmethod
      method txdatak0(); return pcie.txd.atak0; endmethod
      method txdatak1(); return pcie.txd.atak1; endmethod
      method txdatak2(); return pcie.txd.atak2; endmethod
      method txdatak3(); return pcie.txd.atak3; endmethod
      method txdatak4(); return pcie.txd.atak4; endmethod
      method txdatak5(); return pcie.txd.atak5; endmethod
      method txdatak6(); return pcie.txd.atak6; endmethod
      method txdatak7(); return pcie.txd.atak7; endmethod
      method txdeemph0(); return pcie.txd.eemph0; endmethod
      method txdeemph1(); return pcie.txd.eemph1; endmethod
      method txdeemph2(); return pcie.txd.eemph2; endmethod
      method txdeemph3(); return pcie.txd.eemph3; endmethod
      method txdeemph4(); return pcie.txd.eemph4; endmethod
      method txdeemph5(); return pcie.txd.eemph5; endmethod
      method txdeemph6(); return pcie.txd.eemph6; endmethod
      method txdeemph7(); return pcie.txd.eemph7; endmethod
      method txdetectrx0(); return pcie.txd.etectrx0; endmethod
      method txdetectrx1(); return pcie.txd.etectrx1; endmethod
      method txdetectrx2(); return pcie.txd.etectrx2; endmethod
      method txdetectrx3(); return pcie.txd.etectrx3; endmethod
      method txdetectrx4(); return pcie.txd.etectrx4; endmethod
      method txdetectrx5(); return pcie.txd.etectrx5; endmethod
      method txdetectrx6(); return pcie.txd.etectrx6; endmethod
      method txdetectrx7(); return pcie.txd.etectrx7; endmethod
      method txelecidle0(); return pcie.txe.lecidle0; endmethod
      method txelecidle1(); return pcie.txe.lecidle1; endmethod
      method txelecidle2(); return pcie.txe.lecidle2; endmethod
      method txelecidle3(); return pcie.txe.lecidle3; endmethod
      method txelecidle4(); return pcie.txe.lecidle4; endmethod
      method txelecidle5(); return pcie.txe.lecidle5; endmethod
      method txelecidle6(); return pcie.txe.lecidle6; endmethod
      method txelecidle7(); return pcie.txe.lecidle7; endmethod
      method txmargin0(); return pcie.txm.argin0; endmethod
      method txmargin1(); return pcie.txm.argin1; endmethod
      method txmargin2(); return pcie.txm.argin2; endmethod
      method txmargin3(); return pcie.txm.argin3; endmethod
      method txmargin4(); return pcie.txm.argin4; endmethod
      method txmargin5(); return pcie.txm.argin5; endmethod
      method txmargin6(); return pcie.txm.argin6; endmethod
      method txmargin7(); return pcie.txm.argin7; endmethod
      method txswing0(); return pcie.txs.wing0; endmethod
      method txswing1(); return pcie.txs.wing1; endmethod
      method txswing2(); return pcie.txs.wing2; endmethod
      method txswing3(); return pcie.txs.wing3; endmethod
      method txswing4(); return pcie.txs.wing4; endmethod
      method txswing5(); return pcie.txs.wing5; endmethod
      method txswing6(); return pcie.txs.wing6; endmethod
      method txswing7(); return pcie.txs.wing7; endmethod
      method powerdown0(); return pcie.power.down0; endmethod
      method powerdown1(); return pcie.power.down1; endmethod
      method powerdown2(); return pcie.power.down2; endmethod
      method powerdown3(); return pcie.power.down3; endmethod
      method powerdown4(); return pcie.power.down4; endmethod
      method powerdown5(); return pcie.power.down5; endmethod
      method powerdown6(); return pcie.power.down6; endmethod
      method powerdown7(); return pcie.power.down7; endmethod
      method phystatus0 = pcie.phy.status0;
      method phystatus1 = pcie.phy.status1;
      method phystatus2 = pcie.phy.status2;
      method phystatus3 = pcie.phy.status3;
      method phystatus4 = pcie.phy.status4;
      method phystatus5 = pcie.phy.status5;
      method phystatus6 = pcie.phy.status6;
      method phystatus7 = pcie.phy.status7;
      method eidleinfersel0(); return pcie.eidle.infersel0; endmethod
      method eidleinfersel1(); return pcie.eidle.infersel1; endmethod
      method eidleinfersel2(); return pcie.eidle.infersel2; endmethod
      method eidleinfersel3(); return pcie.eidle.infersel3; endmethod
      method eidleinfersel4(); return pcie.eidle.infersel4; endmethod
      method eidleinfersel5(); return pcie.eidle.infersel5; endmethod
      method eidleinfersel6(); return pcie.eidle.infersel6; endmethod
      method eidleinfersel7(); return pcie.eidle.infersel7; endmethod
      method sim_pipe_pclk_in = pcie.sim.pipe_pclk_in;
      method sim_ltssmstate(); return pcie.sim.ltssmstate; endmethod
      method sim_pipe_rate(); return pcie.sim.pipe_rate; endmethod
   endinterface
`endif

   interface PcieS5HipCtrl hip_ctrl;
      method test_in = pcie.test.in;
      method simu_mode_pipe = pcie.simu.mode_pipe;
   endinterface
endmodule

// Altera PCIe HIP Reset

(* always_ready, always_enabled *)
interface AlteraPcieHipRs;
(* prefix="", result="dlup_exit" *)   method Action dlup_exit(Bit#(1) dlup_exit);
(* prefix="", result="hotrst_exit" *) method Action hotrst_exit(Bit#(1) hotrst_exit);
(* prefix="", result="l2_exit" *)     method Action l2_exit(Bit#(1) l2_exit);
(* prefix="", result="ltssm" *)       method Action ltssm(Bit#(5) ltssm);
(* prefix="", result="test_sim" *)    method Action test_sim(Bit#(1) test_sim);
   method Reset app_rstn;
endinterface

typedef enum {
   LTSSM_POL = 5'b00010,
   LTSSM_CPL = 5'b00011,
   LTSSM_DET = 5'b00000,
   LTSSM_RCV = 5'b01100,
   LTSSM_DIS = 5'b10000
} LTSSM deriving (Bits, Eq);

typedef enum {
   RCV_TIMEOUT = 23'd6000000
} TIMEOUT deriving (Bits, Eq);

typedef enum {
   RSTN_CNT_MAX = 11'h400,
   RSTN_CTN_MAX_SIM = 11'h20
} RSTN_CNT deriving (Bits, Eq);

//(* synthesize, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
(* always_ready, always_enabled, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkAlteraPcieHipRs#(Clock pld_clk, Reset npor)(AlteraPcieHipRs);
   Reset npor_sync_pld_clk          <- mkAsyncReset(3, npor, pld_clk);
   Reg #(Bit#(5)) ltssm_r           <- mkReg(0, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));
   Reg #(Bit#(1)) dlup_exit_r       <- mkReg(1, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));
   Reg #(Bit#(1)) hotrst_exit_r     <- mkReg(1, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));
   Reg #(Bit#(1)) l2_exit_r         <- mkReg(1, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));
   Reg #(Bit#(11)) rsnt_cntn        <- mkReg(0, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));
   Reg #(Bit#(23)) recovery_cnt     <- mkReg(0, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));
   Reg #(Bit#(1)) recovery_rst      <- mkReg(0, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));
   Reg #(Bit#(1)) exits_r           <- mkReg(0, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));

   let app_rstn_out <- mkReset(0, True, pld_clk, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));

   rule exit_v ((l2_exit_r == 1'b0) || (hotrst_exit_r == 1'b0) || (dlup_exit_r == 1'b0) || (ltssm_r == pack(LTSSM_DIS)) || (recovery_rst == 1'b1));
      exits_r <= 1'b1;
   endrule

   //Delay HIP reset upon npor
   rule delay_hip0 if (exits_r == 1'b1);
      rsnt_cntn <= 11'h3f0;
   endrule

   rule delay_hip1 if (exits_r != 1'b1);
      rsnt_cntn <= rsnt_cntn + 11'h1;
   endrule

   rule delay_hip2 if ((exits_r != 1'b1) && (rsnt_cntn == pack(RSTN_CNT_MAX)));
      app_rstn_out.assertReset;
   endrule

   // Monitor if LTSSM is frozen in RECOVERY state
   // Issue reset if timeout RCV_TIMEOUT
   rule recovery_cnt0 ((recovery_cnt != pack(RCV_TIMEOUT)) && (ltssm_r != pack(LTSSM_RCV)));
      recovery_cnt <= 23'b0;
   endrule

   rule recovery_cnt1 ((recovery_cnt == pack(RCV_TIMEOUT)) && (ltssm_r == pack(LTSSM_RCV)));
      recovery_cnt <= recovery_cnt;
   endrule

   rule recovery_cnt2 ((recovery_cnt != pack(RCV_TIMEOUT)) && (ltssm_r == pack(LTSSM_RCV)));
      recovery_cnt <= recovery_cnt + 23'h1;
   endrule

   rule recovery_rst0 (recovery_cnt == pack(RCV_TIMEOUT));
      recovery_rst <= 1'b1;
   endrule

   rule recovery_rst1 (ltssm_r != pack(LTSSM_RCV) && recovery_cnt != pack(RCV_TIMEOUT));
      recovery_rst <= 1'b0;
   endrule

   // interface
   method Action dlup_exit(Bit#(1) v);
      dlup_exit_r <= v;
   endmethod

   method Action ltssm(Bit#(5) v);
      ltssm_r <= v;
   endmethod

   method Action l2_exit(Bit#(1) v);
      l2_exit_r <= v;
   endmethod

   method Action hotrst_exit(Bit#(1) v);
      hotrst_exit_r <= v;
   endmethod

   method app_rstn;
      return app_rstn_out.new_rst;
   endmethod
endmodule

// Altera Pcie TL Configuration

interface AlteraPcieTlCfgSample;
   method Action tl_cfg_add(Bit#(4) tl_cfg_add);
   method Action tl_cfg_ctl(Bit#(32) tl_cfg_ctl);
   method Action tl_cfg_ctl_wr(Bit#(1) tl_cfg_ctl_wr);
   method Action tl_cfg_sts(Bit#(53) tl_cfg_sts);
   method Action tl_cfg_sts_wr(Bit#(1) tl_cfg_sts_wr);
   method Bit#(13) cfg_busdev;
   method Bit#(32) cfg_devcsr;
   method Bit#(32) cfg_lnkcsr;
   method Bit#(32) cfg_prmcsr;

   method Bit#(20) cfg_io_bas;
   method Bit#(20) cfg_io_lim;
   method Bit#(12) cfg_np_bas;
   method Bit#(12) cfg_np_lim;
   method Bit#(44) cfg_pr_bas;
   method Bit#(44) cfg_pr_lim;

   method Bit#(24) cfg_tcvcmap;
   method Bit#(16) cfg_msicsr;
endinterface

//(* synthesize *)
(* always_ready, always_enabled,  no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkAlteraPcieTlCfgSample#(Clock pld_clk, Reset rstn)(AlteraPcieTlCfgSample);
   Reg #(Bit#(1)) tl_cfg_ctl_wr_r   <- mkReg(0, clocked_by(pld_clk), reset_by(rstn));
   Reg #(Bit#(1)) tl_cfg_ctl_wr_rr  <- mkReg(0, clocked_by(pld_clk), reset_by(rstn));
   Reg #(Bit#(1)) tl_cfg_ctl_wr_rrr <- mkReg(0, clocked_by(pld_clk), reset_by(rstn));

   Reg #(Bit#(1)) tl_cfg_sts_wr_r   <- mkReg(0, clocked_by(pld_clk), reset_by(rstn));
   Reg #(Bit#(1)) tl_cfg_sts_wr_rr  <- mkReg(0, clocked_by(pld_clk), reset_by(rstn));
   Reg #(Bit#(1)) tl_cfg_sts_wr_rrr <- mkReg(0, clocked_by(pld_clk), reset_by(rstn));

   Reg #(Bit#(4)) tl_cfg_add_wires    <- mkReg(0, clocked_by(pld_clk), reset_by(rstn));
   Reg #(Bit#(32)) tl_cfg_ctl_wires   <- mkReg(0, clocked_by(pld_clk), reset_by(rstn));
   Reg #(Bit#(53)) tl_cfg_sts_wires   <- mkReg(0, clocked_by(pld_clk), reset_by(rstn));
   Reg #(Bit#(1)) tl_cfg_ctl_wr_wires <- mkReg(0, clocked_by(pld_clk), reset_by(rstn));
   Reg #(Bit#(1)) tl_cfg_sts_wr_wires <- mkReg(0, clocked_by(pld_clk), reset_by(rstn));

   Vector#(13, Reg#(Bit#(1))) cfg_busdev_wires   <- replicateM(mkReg(0, clocked_by(pld_clk), reset_by(rstn)));
   Vector#(32, Reg#(Bit#(1))) cfg_devcsr_wires   <- replicateM(mkReg(0, clocked_by(pld_clk), reset_by(rstn)));
   Vector#(32, Reg#(Bit#(1))) cfg_lnkcsr_wires  <- replicateM(mkReg(0, clocked_by(pld_clk), reset_by(rstn)));
   Vector#(32, Reg#(Bit#(1))) cfg_prmcsr_wires   <- replicateM(mkReg(0, clocked_by(pld_clk), reset_by(rstn)));

   Vector#(20, Reg#(Bit#(1))) cfg_io_bas_wires   <- replicateM(mkReg(0, clocked_by(pld_clk), reset_by(rstn)));
   Vector#(20, Reg#(Bit#(1))) cfg_io_lim_wires   <- replicateM(mkReg(0, clocked_by(pld_clk), reset_by(rstn)));
   Vector#(12, Reg#(Bit#(1))) cfg_np_bas_wires   <- replicateM(mkReg(0, clocked_by(pld_clk), reset_by(rstn)));
   Vector#(12, Reg#(Bit#(1))) cfg_np_lim_wires   <- replicateM(mkReg(0, clocked_by(pld_clk), reset_by(rstn)));
   Vector#(44, Reg#(Bit#(1))) cfg_pr_bas_wires   <- replicateM(mkReg(0, clocked_by(pld_clk), reset_by(rstn)));
   Vector#(44, Reg#(Bit#(1))) cfg_pr_lim_wires   <- replicateM(mkReg(0, clocked_by(pld_clk), reset_by(rstn)));
   Vector#(24, Reg#(Bit#(1))) cfg_tcvcmap_wires  <- replicateM(mkReg(0, clocked_by(pld_clk), reset_by(rstn)));
   Vector#(16, Reg#(Bit#(1))) cfg_msicsr_wires   <- replicateM(mkReg(0, clocked_by(pld_clk), reset_by(rstn)));

   rule tl_cfg;
      tl_cfg_ctl_wr_r   <= tl_cfg_ctl_wr_wires;
      tl_cfg_ctl_wr_rr  <= tl_cfg_ctl_wr_r;
      tl_cfg_ctl_wr_rrr <= tl_cfg_ctl_wr_rr;
      tl_cfg_sts_wr_r   <= tl_cfg_sts_wr_wires;
      tl_cfg_sts_wr_rr  <= tl_cfg_sts_wr_r;
      tl_cfg_sts_wr_rrr <= tl_cfg_sts_wr_rr;
   endrule

   rule cfg_constants (True);
      writeVReg(takeAt(25, cfg_prmcsr_wires), unpack(2'h0));
      writeVReg(takeAt(16, cfg_prmcsr_wires), unpack(8'h0));
      writeVReg(takeAt(20, cfg_devcsr_wires), unpack(12'h0));
   endrule

   // tl_cfg_sts sampling
   rule cfg_sts_sampling (tl_cfg_sts_wr_rrr != tl_cfg_sts_wr_rr);
      writeVReg(takeAt(16,  cfg_devcsr_wires), unpack(tl_cfg_sts_wires[52:49]));
      writeVReg(takeAt(16,  cfg_lnkcsr_wires), unpack(tl_cfg_sts_wires[46:31]));
      writeVReg(takeAt(27,  cfg_prmcsr_wires), unpack(tl_cfg_sts_wires[29:25]));
      writeVReg(takeAt(24,  cfg_prmcsr_wires), unpack(tl_cfg_sts_wires[24]));
   endrule

   // tl_cfg_ctl sampling
   rule cfg_ctl_sample (tl_cfg_ctl_wr_rrr != tl_cfg_ctl_wr_rr);
     case (tl_cfg_add_wires)
         4'h0:  writeVReg(take(cfg_devcsr_wires),  unpack(tl_cfg_ctl_wires[31:16]));
         4'h2:  writeVReg(take(cfg_lnkcsr_wires),  unpack(tl_cfg_ctl_wires[31:16]));
         4'h3:  writeVReg(take(cfg_prmcsr_wires),  unpack(tl_cfg_ctl_wires[23:8]));
         4'h5:  writeVReg(take(cfg_io_bas_wires),  unpack(tl_cfg_ctl_wires[19:0]));
         4'h6:  writeVReg(take(cfg_io_lim_wires),  unpack(tl_cfg_ctl_wires[19:0]));
         4'h7:begin
            writeVReg(take(cfg_np_bas_wires),  unpack(tl_cfg_ctl_wires[23:12]));
            writeVReg(take(cfg_np_lim_wires),  unpack(tl_cfg_ctl_wires[11:0]));
         end
         4'h8:  writeVReg(take(cfg_pr_bas_wires),  unpack(tl_cfg_ctl_wires[31:0]));
         4'h9:  writeVReg(takeAt(32, cfg_pr_bas_wires), unpack(tl_cfg_ctl_wires[11:0]));
         4'hA:  writeVReg(take(cfg_pr_lim_wires),  unpack(tl_cfg_ctl_wires[31:0]));
         4'hB:  writeVReg(takeAt(32, cfg_pr_lim_wires), unpack(tl_cfg_ctl_wires[11:0]));
         4'hD:  writeVReg(take(cfg_msicsr_wires),  unpack(tl_cfg_ctl_wires[15:0]));
         4'hE:  writeVReg(take(cfg_tcvcmap_wires), unpack(tl_cfg_ctl_wires[23:0]));
         4'hF:  writeVReg(take(cfg_busdev_wires),  unpack(tl_cfg_ctl_wires[12:0]));
      endcase
   endrule

   method Action tl_cfg_add(Bit#(4) v);
      tl_cfg_add_wires <= v;
   endmethod

   method Action tl_cfg_ctl(Bit#(32) v);
      tl_cfg_ctl_wires <= v;
   endmethod

   method Action tl_cfg_sts(Bit#(53) v);
      tl_cfg_sts_wires <= v;
   endmethod

   method Action tl_cfg_ctl_wr(Bit#(1) v);
      tl_cfg_ctl_wr_wires <= v;
   endmethod

   method Action tl_cfg_sts_wr(Bit#(1) v);
      tl_cfg_sts_wr_wires <= v;
   endmethod

   method cfg_busdev;
      return pack(readVReg(cfg_busdev_wires));
   endmethod

   method cfg_devcsr;
      return pack(readVReg(cfg_devcsr_wires));
   endmethod

   method cfg_lnkcsr;
      return pack(readVReg(cfg_lnkcsr_wires));
   endmethod

   method cfg_prmcsr;
      return pack(readVReg(cfg_prmcsr_wires));
   endmethod

   method cfg_io_bas;
      return pack(readVReg(cfg_io_bas_wires));
   endmethod

   method cfg_io_lim;
      return pack(readVReg(cfg_io_lim_wires));
   endmethod

   method cfg_np_bas;
      return pack(readVReg(cfg_np_bas_wires));
   endmethod

   method cfg_np_lim;
      return pack(readVReg(cfg_np_lim_wires));
   endmethod

   method cfg_pr_bas;
      return pack(readVReg(cfg_pr_bas_wires));
   endmethod

   method cfg_pr_lim;
      return pack(readVReg(cfg_pr_lim_wires));
   endmethod

   method cfg_tcvcmap;
      return pack(readVReg(cfg_tcvcmap_wires));
   endmethod

   method cfg_msicsr;
      return pack(readVReg(cfg_msicsr_wires));
   endmethod
endmodule

