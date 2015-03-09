
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
import ConnectalClocks      ::*;

import ALTERA_XCVR_RECONFIG_WRAPPER        ::*;
import ALTERA_PCIE_RECONFIG_DRIVER_WRAPPER ::*;
import ALTERA_PCIE_WRAPPER                 ::*;
import ALTERA_PLL_WRAPPER                  ::*;

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
interface PcieS5RxSpecific;
   method Action   mask(Bit#(1) mask);
   method Bit#(8)  bar();
   method Bit#(16) be();
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
(* prefix="", result="in" *)   method Action in(Vector#(8, Bit#(1)) a);
endinterface

(* always_ready, always_enabled *)
interface PcieS5Txout;
   method Vector#(8, Bit#(1)) out();
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

interface PcieS5HipPipe;
(* prefix="", result="rxdata" *)     method Action     rxdata    (Vector#(8, Bit#(8)) rxdata);
(* prefix="", result="rxdatak" *)    method Action     rxdatak   (Vector#(8, Bit#(1)) rxdatak);
(* prefix="", result="rxelecidle" *) method Action     rxelecidle(Vector#(8, Bit#(1)) rxelecidle);
(* prefix="", result="rxstatus" *)   method Action     rxstatus  (Vector#(8, Bit#(3)) rxstatus);
(* prefix="", result="rxvalid" *)    method Action     rxvalid   (Vector#(8, Bit#(1)) rxvalid);
(* prefix="", result="phystatus" *)  method Action     phystatus (Vector#(8, Bit#(1)) phystatus);
(* prefix="", result="sim_pipe_pclk_in" *) method Action sim_pipe_pclk_in(Bit#(1) sim_pipe_pclk_in);
    method Vector#(8, Bit#(1))    rxpolarity();
    method Vector#(8, Bit#(1))    txcompl();
    method Vector#(8, Bit#(8))    txdata();
    method Vector#(8, Bit#(1))    txdatak();
    method Vector#(8, Bit#(1))    txdeemph();
    method Vector#(8, Bit#(1))    txdetectrx();
    method Vector#(8, Bit#(1))    txelecidle();
    method Vector#(8, Bit#(3))    txmargin();
    method Vector#(8, Bit#(1))    txswing();
    method Vector#(8, Bit#(2))    powerdown();
    method Vector#(8, Bit#(3))    eidleinfersel();
    method Bit#(5)    sim_ltssmstate();
    method Bit#(2)    sim_pipe_rate();
endinterface

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
   interface PcieS5RxSpecific rx_specific;
   interface PcieS5TlCfg tl;
   interface PcieS5HipRst hip_rst;
   interface PcieS5TxCred tx_cred;
   interface PcieS5Rxin rx;
   interface PcieS5Txout tx;
   interface PcieS5HipStatus hip_status;
   interface PcieS5HipPipe hip_pipe;
   interface PcieS5HipCtrl hip_ctrl;
   interface Clock coreclkout_hip;
endinterface

//(* synthesize *)
module mkPcieS5Wrap#(Clock clk_100Mhz, Clock clk_50Mhz, Reset npor, Reset pin_perst)(PcieS5Wrap#(12, 32, 128));

   Vector#(8, Wire#(Bit#(1))) rx_in_wires <- replicateM(mkDWire(0));
   Vector#(8, Wire#(Bit#(8))) rxdata_wires <- replicateM(mkDWire(0));
   Vector#(8, Wire#(Bit#(1))) rxdatak_wires <- replicateM(mkDWire(0));
   Vector#(8, Wire#(Bit#(1))) rxelecidle_wires <- replicateM(mkDWire(0));
   Vector#(8, Wire#(Bit#(3))) rxstatus_wires  <- replicateM(mkDWire(0));
   Vector#(8, Wire#(Bit#(1))) rxvalid_wires   <- replicateM(mkDWire(0));
   Vector#(8, Wire#(Bit#(1))) phystatus_wires <- replicateM(mkDWire(0));

   Clock default_clock <- exposeCurrentClock;
   Reset default_reset <- exposeCurrentReset;
   Reset reset_high <- invertCurrentReset;

   PcieWrap         pcie     <- mkPcieWrap(clk_100Mhz, npor, pin_perst, reset_high);

   Clock coreclk = pcie.coreclkout.hip;
   PcieReconfigWrap pcie_cfg <- mkPcieReconfigWrap(coreclk, clk_50Mhz, npor, reset_high, reset_high);
   XcvrReconfigWrap xcvr_cfg <- mkXcvrReconfigWrap(clk_50Mhz, reset_high, reset_high);

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

   (* no_implicit_conditions *)
   rule pcie_rx;
      pcie.rx.in0(rx_in_wires[0]);
      pcie.rx.in1(rx_in_wires[1]);
      pcie.rx.in2(rx_in_wires[2]);
      pcie.rx.in3(rx_in_wires[3]);
      pcie.rx.in4(rx_in_wires[4]);
      pcie.rx.in5(rx_in_wires[5]);
      pcie.rx.in6(rx_in_wires[6]);
      pcie.rx.in7(rx_in_wires[7]);
   endrule

   (* no_implicit_conditions *)
   rule pcie_rxdata;
      pcie.rxd.ata0(rxdata_wires[0]);
      pcie.rxd.ata1(rxdata_wires[1]);
      pcie.rxd.ata2(rxdata_wires[2]);
      pcie.rxd.ata3(rxdata_wires[3]);
      pcie.rxd.ata4(rxdata_wires[4]);
      pcie.rxd.ata5(rxdata_wires[5]);
      pcie.rxd.ata6(rxdata_wires[6]);
      pcie.rxd.ata7(rxdata_wires[7]);
   endrule

   (* no_implicit_conditions *)
   rule pcie_rxdatak;
      pcie.rxd.atak0(rxdatak_wires[0]);
      pcie.rxd.atak1(rxdatak_wires[1]);
      pcie.rxd.atak2(rxdatak_wires[2]);
      pcie.rxd.atak3(rxdatak_wires[3]);
      pcie.rxd.atak4(rxdatak_wires[4]);
      pcie.rxd.atak5(rxdatak_wires[5]);
      pcie.rxd.atak6(rxdatak_wires[6]);
      pcie.rxd.atak7(rxdatak_wires[7]);
   endrule

   (* no_implicit_conditions *)
   rule pcie_rxelecidle;
      pcie.rxe.lecidle0(rxelecidle_wires[0]);
      pcie.rxe.lecidle1(rxelecidle_wires[1]);
      pcie.rxe.lecidle2(rxelecidle_wires[2]);
      pcie.rxe.lecidle3(rxelecidle_wires[3]);
      pcie.rxe.lecidle4(rxelecidle_wires[4]);
      pcie.rxe.lecidle5(rxelecidle_wires[5]);
      pcie.rxe.lecidle6(rxelecidle_wires[6]);
      pcie.rxe.lecidle7(rxelecidle_wires[7]);
   endrule

   (* no_implicit_conditions *)
   rule pcie_rxstatus;
      pcie.rxs.tatus0(rxstatus_wires[0]);
      pcie.rxs.tatus1(rxstatus_wires[1]);
      pcie.rxs.tatus2(rxstatus_wires[2]);
      pcie.rxs.tatus3(rxstatus_wires[3]);
      pcie.rxs.tatus4(rxstatus_wires[4]);
      pcie.rxs.tatus5(rxstatus_wires[5]);
      pcie.rxs.tatus6(rxstatus_wires[6]);
      pcie.rxs.tatus7(rxstatus_wires[7]);
   endrule

   (* no_implicit_conditions *)
   rule pcie_rxvalid;
      pcie.rxv.alid0(rxvalid_wires[0]);
      pcie.rxv.alid1(rxvalid_wires[1]);
      pcie.rxv.alid2(rxvalid_wires[2]);
      pcie.rxv.alid3(rxvalid_wires[3]);
      pcie.rxv.alid4(rxvalid_wires[4]);
      pcie.rxv.alid5(rxvalid_wires[5]);
      pcie.rxv.alid6(rxvalid_wires[6]);
      pcie.rxv.alid7(rxvalid_wires[7]);
   endrule

   (* no_implicit_conditions *)
   rule pcie_phystatus;
      pcie.phy.status0(phystatus_wires[0]);
      pcie.phy.status1(phystatus_wires[1]);
      pcie.phy.status2(phystatus_wires[2]);
      pcie.phy.status3(phystatus_wires[3]);
      pcie.phy.status4(phystatus_wires[4]);
      pcie.phy.status5(phystatus_wires[5]);
      pcie.phy.status6(phystatus_wires[6]);
      pcie.phy.status7(phystatus_wires[7]);
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

   interface PcieS5RxSpecific rx_specific;
      method mask = pcie.rx_s.t_mask;
      method Bit#(8) bar (); return pcie.rx_s.t_bar; endmethod
      method Bit#(16) be();  return pcie.rx_s.t_be;  endmethod
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
      method Action in(Vector#(8, Bit#(1)) a);
         writeVReg(rx_in_wires, a);
      endmethod
   endinterface

   interface PcieS5Txout tx;
      method Vector#(8, Bit#(1)) out();
         Vector#(8, Bit#(1)) ret_val;
         ret_val[0] = pcie.tx.out0;
         ret_val[1] = pcie.tx.out1;
         ret_val[2] = pcie.tx.out2;
         ret_val[3] = pcie.tx.out3;
         ret_val[4] = pcie.tx.out4;
         ret_val[5] = pcie.tx.out5;
         ret_val[6] = pcie.tx.out6;
         ret_val[7] = pcie.tx.out7;
         return ret_val;
      endmethod
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

   interface PcieS5HipPipe hip_pipe;
      method Action rxdata(Vector#(8, Bit#(8)) a);
         writeVReg(rxdata_wires, a);
      endmethod

      method Action rxdatak(Vector#(8, Bit#(1)) a);
         writeVReg(rxdatak_wires, a);
      endmethod

      method Action rxelecidle(Vector#(8, Bit#(1)) a);
         writeVReg(rxelecidle_wires, a);
      endmethod

      method Action rxstatus(Vector#(8, Bit#(3)) a);
         writeVReg(rxstatus_wires, a);
      endmethod

      method Action rxvalid(Vector#(8, Bit#(1)) a);
         writeVReg(rxvalid_wires, a);
      endmethod

      method Action phystatus(Vector#(8, Bit#(1)) a);
         writeVReg(phystatus_wires, a);
      endmethod

      method rxpolarity();
         Vector#(8, Bit#(1)) retval;
         retval = unpack({pcie.rxp.olarity7,
                          pcie.rxp.olarity6,
                          pcie.rxp.olarity5,
                          pcie.rxp.olarity4,
                          pcie.rxp.olarity3,
                          pcie.rxp.olarity2,
                          pcie.rxp.olarity1,
                          pcie.rxp.olarity0});
         return retval;
      endmethod

      method txcompl();
         Vector#(8, Bit#(1)) retval;
         retval = unpack({pcie.txc.ompl7,
                          pcie.txc.ompl6,
                          pcie.txc.ompl5,
                          pcie.txc.ompl4,
                          pcie.txc.ompl3,
                          pcie.txc.ompl2,
                          pcie.txc.ompl1,
                          pcie.txc.ompl0});
         return retval;
      endmethod

      method txdata();
         Vector#(8, Bit#(8)) retval;
         retval = unpack({pcie.txd.ata7,
                          pcie.txd.ata6,
                          pcie.txd.ata5,
                          pcie.txd.ata4,
                          pcie.txd.ata3,
                          pcie.txd.ata2,
                          pcie.txd.ata1,
                          pcie.txd.ata0});
         return retval;
      endmethod

      method txdatak();
         Vector#(8, Bit#(1)) retval;
         retval = unpack({pcie.txd.atak7,
                          pcie.txd.atak6,
                          pcie.txd.atak5,
                          pcie.txd.atak4,
                          pcie.txd.atak3,
                          pcie.txd.atak2,
                          pcie.txd.atak1,
                          pcie.txd.atak0});
         return retval;
      endmethod

      method txdeemph();
         Vector#(8, Bit#(1)) retval;
         retval = unpack({pcie.txd.eemph7,
                          pcie.txd.eemph6,
                          pcie.txd.eemph5,
                          pcie.txd.eemph4,
                          pcie.txd.eemph3,
                          pcie.txd.eemph2,
                          pcie.txd.eemph1,
                          pcie.txd.eemph0});
         return retval;
      endmethod

      method txdetectrx();
         Vector#(8, Bit#(1)) retval;
         retval = unpack({pcie.txd.etectrx7,
                          pcie.txd.etectrx6,
                          pcie.txd.etectrx5,
                          pcie.txd.etectrx4,
                          pcie.txd.etectrx3,
                          pcie.txd.etectrx2,
                          pcie.txd.etectrx1,
                          pcie.txd.etectrx0});
         return retval;
      endmethod

      method txelecidle();
         Vector#(8, Bit#(1)) retval;
         retval = unpack({pcie.txe.lecidle7,
                          pcie.txe.lecidle6,
                          pcie.txe.lecidle5,
                          pcie.txe.lecidle4,
                          pcie.txe.lecidle3,
                          pcie.txe.lecidle2,
                          pcie.txe.lecidle1,
                          pcie.txe.lecidle0});
         return retval;
      endmethod

      method txmargin();
         Vector#(8, Bit#(3)) retval;
         retval = unpack({pcie.txm.argin7,
                          pcie.txm.argin6,
                          pcie.txm.argin5,
                          pcie.txm.argin4,
                          pcie.txm.argin3,
                          pcie.txm.argin2,
                          pcie.txm.argin1,
                          pcie.txm.argin0});
         return retval;
      endmethod

      method txswing();
         Vector#(8, Bit#(1)) retval;
         retval = unpack({pcie.txs.wing7,
                          pcie.txs.wing6,
                          pcie.txs.wing5,
                          pcie.txs.wing4,
                          pcie.txs.wing3,
                          pcie.txs.wing2,
                          pcie.txs.wing1,
                          pcie.txs.wing0});
         return retval;
      endmethod

      method powerdown();
         Vector#(8, Bit#(2)) retval;
         retval = unpack({pcie.power.down7,
                          pcie.power.down6,
                          pcie.power.down5,
                          pcie.power.down4,
                          pcie.power.down3,
                          pcie.power.down2,
                          pcie.power.down1,
                          pcie.power.down0});
         return retval;
      endmethod

      method eidleinfersel();
         Vector#(8, Bit#(3)) retval;
         retval = unpack({pcie.eidle.infersel7,
                          pcie.eidle.infersel6,
                          pcie.eidle.infersel5,
                          pcie.eidle.infersel4,
                          pcie.eidle.infersel3,
                          pcie.eidle.infersel2,
                          pcie.eidle.infersel1,
                          pcie.eidle.infersel0});
         return retval;
      endmethod

      method sim_pipe_pclk_in = pcie.sim.pipe_pclk_in;

      method sim_ltssmstate(); return pcie.sim.ltssmstate; endmethod
      method sim_pipe_rate(); return pcie.sim.pipe_rate; endmethod
   endinterface

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

