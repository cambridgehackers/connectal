
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
   method Bit#(1) serdespll_locked();
   method Bit#(1) pldclk_inuse();
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
   method Bit#(1) cfg_par_err;
   method Bit#(12) ko_cpl_spc_data;
   method Bit#(8) ko_cpl_spc_header;
endinterface

interface PcieS5HipSerial;
   interface PcieS5Rxin rx;
   interface PcieS5Txout tx;
endinterface

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
   interface PcieS5HipPipe hip_pipe;
endinterface

module mkConnectReconfig #(PcieReconfigWrap pcie_reconfig, XcvrReconfigWrap xcvr_reconfig) (Empty);
   XcvrreconfigwrapReconfig_mgmt xcvr_cfg_mgmt = xcvr_reconfig.reconfig_mgmt;
   PciereconfigwrapReconfig_mgmt pcie_cfg_mgmt = pcie_reconfig.reconfig_mgmt;
   (* no_implicit_conditions *)
   rule connectReconfigMgmt;
      xcvr_cfg_mgmt.read(pcie_cfg_mgmt.read);
      xcvr_cfg_mgmt.write(pcie_cfg_mgmt.write);
      xcvr_cfg_mgmt.address(pcie_cfg_mgmt.address);
      xcvr_cfg_mgmt.writedata(pcie_cfg_mgmt.writedata);
      pcie_cfg_mgmt.readdata(xcvr_cfg_mgmt.readdata);
      pcie_cfg_mgmt.waitrequest(xcvr_cfg_mgmt.waitrequest);
   endrule
endmodule

module mkConnectBusy #(PcieReconfigWrap pcie_reconfig, XcvrReconfigWrap xcvr_reconfig) (Empty);
   (* no_implicit_conditions *)
   rule connectBusy;
      pcie_reconfig.reconfig_b.usy(xcvr_reconfig.reconfig.busy);
   endrule
endmodule

module mkConnectHipStatus #(PcieWrap pcie, PcieReconfigWrap pcie_reconfig) (Empty);
   (* no_implicit_conditions *)
   rule connectHipStatus;
      pcie_reconfig.derr.cor_ext_rcv_drv(pcie.derr.cor_ext_rcv);
      pcie_reconfig.derr.cor_ext_rpl_drv(pcie.derr.cor_ext_rpl);
      pcie_reconfig.derr.rpl_drv(pcie.derr.rpl);
      pcie_reconfig.dlup.drv(pcie.dl.up);
      pcie_reconfig.dlup.exit_drv(pcie.dl.up_exit);
      pcie_reconfig.ev128ns.drv(pcie.ev128.ns);
      pcie_reconfig.ev1us.drv(pcie.ev1.us);
      pcie_reconfig.hotrst.exit_drv(pcie.hotrst.exit);
      pcie_reconfig.int_status.drv(pcie.in.t_status);
      pcie_reconfig.lane_act.drv(pcie.lane.act);
      pcie_reconfig.l2_exit.drv(pcie.l2.exit);
      pcie_reconfig.ltssmstate.drv(pcie.ltssm.state);
      pcie_reconfig.tx_par_err.drv(pcie.tx_par.err);
      pcie_reconfig.rx_par_err.drv(pcie.rx_par.err);
      pcie_reconfig.cfg_par_err.drv(pcie.cfg_par.err);
      pcie_reconfig.ko.cpl_spc_data_drv(pcie.ko.cpl_spc_data);
      pcie_reconfig.ko.cpl_spc_header_drv(pcie.ko.cpl_spc_header);
   endrule
endmodule

module mkConnectCurrentSpeed#(PcieWrap pcie, PcieReconfigWrap pcie_reconfig) (Empty);
   (* no_implicit_conditions *)
   rule connectCurrentSpeed;
      pcie_reconfig.current.speed(pcie.current.speed);
   endrule
endmodule

module mkConnectReconfigXcvr#(PcieWrap pcie, XcvrReconfigWrap xcvr) (Empty);
   (* no_implicit_conditions *)
   rule connectXcvrReconfig;
      pcie.reconfig.to_xcvr(xcvr.reconfig.to_xcvr);
      xcvr.reconfig.from_xcvr(pcie.reconfig.from_xcvr);
   endrule
endmodule

module mkPcieS5Wrap#(Clock app_clk, Clock pcie_clk, Reset pcie_clk_rst, Clock reconfig_clk, Reset reconfig_clk_rst)(PcieS5Wrap#(12, 32, 128));

   PcieReconfigWrap pcie_cfg <- mkPcieReconfigWrap(app_clk, reconfig_clk, pcie_clk_rst, reconfig_clk_rst, reconfig_clk_rst);
   XcvrReconfigWrap xcvr_cfg <- mkXcvrReconfigWrap(reconfig_clk, reconfig_clk_rst, reconfig_clk_rst);
   PcieWrap         pcie     <- mkPcieWrap(pcie_clk, pcie_clk_rst, reconfig_clk_rst);

   // connect
   mkConnectReconfig(pcie_cfg, xcvr_cfg);
   // connect hip_status
   mkConnectHipStatus(pcie, pcie_cfg);
   // connect currentspeed
   mkConnectCurrentSpeed(pcie, pcie_cfg);
   // connect xcvr reconfiguration
   mkConnectReconfigXcvr(pcie, xcvr_cfg);
   // connect reconfig busy
   mkConnectBusy(pcie_cfg, xcvr_cfg);

   rule power_mgmt;
      pcie.pm.auxpwr(0);
      pcie.pm.data(10'b0);
      pcie.pm_e.vent(0);
      pcie.pme.to_cr(0);
      pcie.hpg.ctrler(5'b0);
   endrule

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
      method Bit#(1)   sop();   return pcie.rx.st_sop;   endmethod
      method Bit#(1)   eop();   return pcie.rx.st_eop;   endmethod
      method Bit#(128) data();  return pcie.rx.st_data;  endmethod
      method Bit#(1)   valid(); return pcie.rx.st_valid; endmethod
      method Bit#(1)   err();   return pcie.rx.st_err;   endmethod
      method Bit#(2)   empty(); return pcie.rx.st_empty; endmethod
      method ready = pcie.rx.st_ready;
   endinterface

   interface PcieS5TxSt tx_st;
      method Bit#(1) ready (); return pcie.tx.st_ready; endmethod
      method sop = pcie.tx.st_sop;
      method eop = pcie.tx.st_eop;
      method valid = pcie.tx.st_valid;
      method err = pcie.tx.st_err;
      method empty = pcie.tx.st_empty;
      method data = pcie.tx.st_data;
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
      method mask = pcie.rx.st_mask;
      method Bit#(8) bar (); return pcie.rx.st_bar; endmethod
   endinterface

   interface PcieS5HipRst hip_rst;
      method Bit#(1) serdespll_locked(); return pcie.serdes.pll_locked; endmethod
      method Bit#(1) pldclk_inuse(); return pcie.pld_clk.inuse; endmethod
      method core_ready = pcie.pld_cor.e_ready;
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
      method Bit#(4) int_status;  return pcie.in.t_status;      endmethod
      method Bit#(1) l2_exit;     return pcie.l2.exit;          endmethod
      method Bit#(4) lane_act;    return pcie.lane.act;         endmethod
      method Bit#(5) ltssmstate;  return pcie.ltssm.state;      endmethod
      method Bit#(1) rx_par_err;  return pcie.rx_par.err;       endmethod
      method Bit#(2) tx_par_err;  return pcie.tx_par.err;       endmethod
      method Bit#(1) cfg_par_err; return pcie.cfg_par.err;      endmethod
      method Bit#(12) ko_cpl_spc_data; return pcie.ko.cpl_spc_data; endmethod
      method Bit#(8) ko_cpl_spc_header;return pcie.ko.cpl_spc_header;endmethod
   endinterface

   interface PcieS5HipPipe hip_pipe;
      method rxdata0 = pcie.rx.data0;
      method rxdata1 = pcie.rx.data1;
      method rxdata2 = pcie.rx.data2;
      method rxdata3 = pcie.rx.data3;
      method rxdata4 = pcie.rx.data4;
      method rxdata5 = pcie.rx.data5;
      method rxdata6 = pcie.rx.data6;
      method rxdata7 = pcie.rx.data7;
      method rxdatak0 = pcie.rx.datak0;
      method rxdatak1 = pcie.rx.datak1;
      method rxdatak2 = pcie.rx.datak2;
      method rxdatak3 = pcie.rx.datak3;
      method rxdatak4 = pcie.rx.datak4;
      method rxdatak5 = pcie.rx.datak5;
      method rxdatak6 = pcie.rx.datak6;
      method rxdatak7 = pcie.rx.datak7;
      method rxelecidle0 = pcie.rx.elecidle0;
      method rxelecidle1 = pcie.rx.elecidle1;
      method rxelecidle2 = pcie.rx.elecidle2;
      method rxelecidle3 = pcie.rx.elecidle3;
      method rxelecidle4 = pcie.rx.elecidle4;
      method rxelecidle5 = pcie.rx.elecidle5;
      method rxelecidle6 = pcie.rx.elecidle6;
      method rxelecidle7 = pcie.rx.elecidle7;
      method rxpolarity0(); return pcie.rx.polarity0; endmethod
      method rxpolarity1(); return pcie.rx.polarity1; endmethod
      method rxpolarity2(); return pcie.rx.polarity2; endmethod
      method rxpolarity3(); return pcie.rx.polarity3; endmethod
      method rxpolarity4(); return pcie.rx.polarity4; endmethod
      method rxpolarity5(); return pcie.rx.polarity5; endmethod
      method rxpolarity6(); return pcie.rx.polarity6; endmethod
      method rxpolarity7(); return pcie.rx.polarity7; endmethod
      method rxstatus0 = pcie.rx.status0;
      method rxstatus1 = pcie.rx.status1;
      method rxstatus2 = pcie.rx.status2;
      method rxstatus3 = pcie.rx.status3;
      method rxstatus4 = pcie.rx.status4;
      method rxstatus5 = pcie.rx.status5;
      method rxstatus6 = pcie.rx.status6;
      method rxstatus7 = pcie.rx.status7;
      method rxvalid0 = pcie.rx.valid0;
      method rxvalid1 = pcie.rx.valid1;
      method rxvalid2 = pcie.rx.valid2;
      method rxvalid3 = pcie.rx.valid3;
      method rxvalid4 = pcie.rx.valid4;
      method rxvalid5 = pcie.rx.valid5;
      method rxvalid6 = pcie.rx.valid6;
      method rxvalid7 = pcie.rx.valid7;
      method txcompl0(); return pcie.tx.compl0; endmethod
      method txcompl1(); return pcie.tx.compl1; endmethod
      method txcompl2(); return pcie.tx.compl2; endmethod
      method txcompl3(); return pcie.tx.compl3; endmethod
      method txcompl4(); return pcie.tx.compl4; endmethod
      method txcompl5(); return pcie.tx.compl5; endmethod
      method txcompl6(); return pcie.tx.compl6; endmethod
      method txcompl7(); return pcie.tx.compl7; endmethod
      method txdata0(); return pcie.tx.data0; endmethod
      method txdata1(); return pcie.tx.data1; endmethod
      method txdata2(); return pcie.tx.data2; endmethod
      method txdata3(); return pcie.tx.data3; endmethod
      method txdata4(); return pcie.tx.data4; endmethod
      method txdata5(); return pcie.tx.data5; endmethod
      method txdata6(); return pcie.tx.data6; endmethod
      method txdata7(); return pcie.tx.data7; endmethod
      method txdatak0(); return pcie.tx.datak0; endmethod
      method txdatak1(); return pcie.tx.datak1; endmethod
      method txdatak2(); return pcie.tx.datak2; endmethod
      method txdatak3(); return pcie.tx.datak3; endmethod
      method txdatak4(); return pcie.tx.datak4; endmethod
      method txdatak5(); return pcie.tx.datak5; endmethod
      method txdatak6(); return pcie.tx.datak6; endmethod
      method txdatak7(); return pcie.tx.datak7; endmethod
      method txdeemph0(); return pcie.tx.deemph0; endmethod
      method txdeemph1(); return pcie.tx.deemph1; endmethod
      method txdeemph2(); return pcie.tx.deemph2; endmethod
      method txdeemph3(); return pcie.tx.deemph3; endmethod
      method txdeemph4(); return pcie.tx.deemph4; endmethod
      method txdeemph5(); return pcie.tx.deemph5; endmethod
      method txdeemph6(); return pcie.tx.deemph6; endmethod
      method txdeemph7(); return pcie.tx.deemph7; endmethod
      method txdetectrx0(); return pcie.tx.detectrx0; endmethod
      method txdetectrx1(); return pcie.tx.detectrx1; endmethod
      method txdetectrx2(); return pcie.tx.detectrx2; endmethod
      method txdetectrx3(); return pcie.tx.detectrx3; endmethod
      method txdetectrx4(); return pcie.tx.detectrx4; endmethod
      method txdetectrx5(); return pcie.tx.detectrx5; endmethod
      method txdetectrx6(); return pcie.tx.detectrx6; endmethod
      method txdetectrx7(); return pcie.tx.detectrx7; endmethod
      method txelecidle0(); return pcie.tx.elecidle0; endmethod
      method txelecidle1(); return pcie.tx.elecidle1; endmethod
      method txelecidle2(); return pcie.tx.elecidle2; endmethod
      method txelecidle3(); return pcie.tx.elecidle3; endmethod
      method txelecidle4(); return pcie.tx.elecidle4; endmethod
      method txelecidle5(); return pcie.tx.elecidle5; endmethod
      method txelecidle6(); return pcie.tx.elecidle6; endmethod
      method txelecidle7(); return pcie.tx.elecidle7; endmethod
      method txmargin0(); return pcie.tx.margin0; endmethod
      method txmargin1(); return pcie.tx.margin1; endmethod
      method txmargin2(); return pcie.tx.margin2; endmethod
      method txmargin3(); return pcie.tx.margin3; endmethod
      method txmargin4(); return pcie.tx.margin4; endmethod
      method txmargin5(); return pcie.tx.margin5; endmethod
      method txmargin6(); return pcie.tx.margin6; endmethod
      method txmargin7(); return pcie.tx.margin7; endmethod
      method txswing0(); return pcie.tx.swing0; endmethod
      method txswing1(); return pcie.tx.swing1; endmethod
      method txswing2(); return pcie.tx.swing2; endmethod
      method txswing3(); return pcie.tx.swing3; endmethod
      method txswing4(); return pcie.tx.swing4; endmethod
      method txswing5(); return pcie.tx.swing5; endmethod
      method txswing6(); return pcie.tx.swing6; endmethod
      method txswing7(); return pcie.tx.swing7; endmethod
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
endmodule

