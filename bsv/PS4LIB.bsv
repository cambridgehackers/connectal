
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

// Stratix IV PCIe Wrapper.
import Clocks        ::*;
import Vector        ::*;
import Connectable   ::*;
import ConnectalAlteraCells ::*;
import ConnectalClocks      ::*;

import ALTERA_PCIE_SIV_WRAPPER                 ::*;

(* always_ready, always_enabled *)
interface PcieLmi#(numeric type address_width, numeric type data_width);
   method Action           rden(Bit#(1) rden);
   method Action           wren(Bit#(1) wren);
   method Action           addr(Bit#(address_width) addr);
   method Action           din(Bit#(data_width) din);
   method Bit#(data_width) dout();
   method Bit#(1)          ack();
endinterface

(* always_ready, always_enabled *)
interface PcieRxSt#(numeric type data_width);
   method Bit#(1)          sop   ;
   method Bit#(1)          eop   ;
   method Bit#(data_width) data  ;
   method Bit#(1)          valid ;
   method Bit#(1)          err   ;
   method Bit#(1)          empty ;
   method Bit#(8)          bar   ;
   method Bit#(16)         be    ;
   method Action           ready(Bit#(1) ready) ;
   method Action           mask(Bit#(1) mask)   ;
endinterface

(* always_ready, always_enabled *)
interface PcieTxSt#(numeric type data_width);
   method Action           sop(Bit#(1) sop);
   method Action           eop(Bit#(1) eop);
   method Action           valid(Bit#(1) valid);
   method Action           err(Bit#(1) err);
   method Action           empty(Bit#(1) empty);
   method Bit#(1)          ready;
   method Action           data(Bit#(data_width) data);
endinterface

(* always_ready, always_enabled *)
interface PcieMsi;
   method Bit#(1)  int_ack();
   method Action   int_sts (Bit#(1) int_sts);
   method Bit#(1)  msi_ack();
   method Action   msi_num(Bit#(5)num);
   method Action   msi_req(Bit#(1)req);
   method Action   msi_tc(Bit#(3)tc);
   method Action   pex_msi_num(Bit#(5) pex_msi_num);
endinterface

(* always_ready, always_enabled *)
interface PcieTlCfg;
   method Bit#(4)  add();
   method Bit#(32) ctl();
   method Bit#(1)  ctl_wr();
   method Bit#(53) sts();
   method Bit#(1)  sts_wr();
   method Action   cpl_pending(Bit#(1) cpl_pending);
   method Action   cpl_err(Bit#(7) cpl_err);
endinterface

(* always_ready, always_enabled *)
interface PcieHipRst;
   method Bit#(1) serdes_pll_locked();
   method Action  reconfig_clk_locked(Bit#(1) locked);
endinterface

(* always_ready, always_enabled *)
interface PcieTxCred;
   method Bit#(36) cred();
endinterface

(* always_ready, always_enabled *)
interface PcieRxin;
(* prefix="", result="in" *)   method Action in((* port="in" *) Vector#(8, Bit#(1)) a);
endinterface

(* always_ready, always_enabled *)
interface PcieTxout;
   method Vector#(8, Bit#(1)) out();
endinterface

interface PcieHipSerial;
   interface PcieRxin rx;
   interface PcieTxout tx;
endinterface

interface PcieHipPipe;
(* prefix="", result="rxdata" *)     method Action     rxdata    (Vector#(8, Bit#(8)) rxdata);
(* prefix="", result="rxdatak" *)    method Action     rxdatak   ((* port="rxdatak" *) Vector#(8, Bit#(1)) rxdatak);
(* prefix="", result="rxelecidle" *) method Action     rxelecidle(Vector#(8, Bit#(1)) rxelecidle);
(* prefix="", result="rxstatus" *)   method Action     rxstatus  (Vector#(8, Bit#(3)) rxstatus);
(* prefix="", result="rxvalid" *)    method Action     rxvalid   (Vector#(8, Bit#(1)) rxvalid);
(* prefix="", result="phystatus" *)  method Action     phystatus (Vector#(1, Bit#(1)) phystatus);
(* prefix="", result="sim_pipe_pclk_in" *) method Action sim_pipe_pclk_in(Bit#(1) sim_pipe_pclk_in);
    method Vector#(8, Bit#(1))    rxpolarity();
    method Vector#(8, Bit#(1))    txcompl();
(* prefix="", result="txdata" *)     method Vector#(8, Bit#(8))    txdata();
    method Vector#(8, Bit#(1))    txdatak();
    method Vector#(1, Bit#(1))    txdetectrx();
    method Vector#(8, Bit#(1))    txelecidle();
    method Vector#(1, Bit#(2))    powerdown();
    method Bit#(5)    sim_ltssmstate();
    method Bit#(1)    sim_pipe_rate();
endinterface

(* always_ready, always_enabled *)
interface PcieHipCtrl;
(* prefix="", result="test_in" *)        method Action test_in(Bit#(40) test_in);
(* prefix="", result="simu_mode_pipe" *) method Action simu_mode_pipe(Bit#(1) simu_mode_pipe);
endinterface

(* always_ready, always_enabled *)
interface PcieWrap#(numeric type address_width, numeric type data_width, numeric type app_width);
   interface PcieLmi#(address_width, data_width) lmi;
   interface PcieRxSt#(app_width) rx_st;
   interface PcieTxSt#(app_width) tx_st;
   interface PcieMsi msi;
   interface PcieTlCfg tl_cfg;
   interface PcieHipRst hip_rst;
   interface PcieTxCred tx_cred;
   interface PcieRxin rx;
   interface PcieTxout tx;
   interface PcieHipPipe hip_pipe;
   interface PcieHipCtrl hip_ctrl;
   interface Clock coreclkout_hip;
   interface Reset core_reset;
endinterface

//(* synthesize *)
module mkPcieS4Wrap#(Clock refclk, Clock reconfig_clk, Clock serdes_clk, Reset pcie_rstn, Reset local_rstn)(PcieWrap#(12, 32, 128));

   Vector#(8, Wire#(Bit#(1))) rx_in_wires <- replicateM(mkDWire(0));
   Vector#(8, Wire#(Bit#(8))) rxdata_wires <- replicateM(mkDWire(0));
   Vector#(8, Wire#(Bit#(1))) rxdatak_wires <- replicateM(mkDWire(0));
   Vector#(8, Wire#(Bit#(1))) rxelecidle_wires <- replicateM(mkDWire(0));
   Vector#(8, Wire#(Bit#(3))) rxstatus_wires  <- replicateM(mkDWire(0));
   Vector#(8, Wire#(Bit#(1))) rxvalid_wires   <- replicateM(mkDWire(0));
   Vector#(1, Wire#(Bit#(1))) phystatus_wires <- replicateM(mkDWire(0));
   Clock default_clock <- exposeCurrentClock;
   Reset default_reset <- exposeCurrentReset;
   Reset reset_high <- invertCurrentReset;

   PcieS4Wrap pcie <- mkPPS4Wrap(refclk, reconfig_clk, serdes_clk, pcie_rstn, local_rstn);

   Clock coreclk = pcie.core.clk_out;
   Reset corerst <- mkSyncReset(1, pcie.sr.stn, coreclk);

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
      pcie.rx.data0_ext(rxdata_wires[0]);
      pcie.rx.data1_ext(rxdata_wires[1]);
      pcie.rx.data2_ext(rxdata_wires[2]);
      pcie.rx.data3_ext(rxdata_wires[3]);
      pcie.rx.data4_ext(rxdata_wires[4]);
      pcie.rx.data5_ext(rxdata_wires[5]);
      pcie.rx.data6_ext(rxdata_wires[6]);
      pcie.rx.data7_ext(rxdata_wires[7]);
   endrule

   (* no_implicit_conditions *)
   rule pcie_rxdatak;
      pcie.rx.datak0_ext(rxdatak_wires[0]);
      pcie.rx.datak1_ext(rxdatak_wires[1]);
      pcie.rx.datak2_ext(rxdatak_wires[2]);
      pcie.rx.datak3_ext(rxdatak_wires[3]);
      pcie.rx.datak4_ext(rxdatak_wires[4]);
      pcie.rx.datak5_ext(rxdatak_wires[5]);
      pcie.rx.datak6_ext(rxdatak_wires[6]);
      pcie.rx.datak7_ext(rxdatak_wires[7]);
   endrule

   (* no_implicit_conditions *)
   rule pcie_rxelecidle;
      pcie.rx.elecidle0_ext(rxelecidle_wires[0]);
      pcie.rx.elecidle1_ext(rxelecidle_wires[1]);
      pcie.rx.elecidle2_ext(rxelecidle_wires[2]);
      pcie.rx.elecidle3_ext(rxelecidle_wires[3]);
      pcie.rx.elecidle4_ext(rxelecidle_wires[4]);
      pcie.rx.elecidle5_ext(rxelecidle_wires[5]);
      pcie.rx.elecidle6_ext(rxelecidle_wires[6]);
      pcie.rx.elecidle7_ext(rxelecidle_wires[7]);
   endrule

   (* no_implicit_conditions *)
   rule pcie_rxstatus;
      pcie.rx.status0_ext(rxstatus_wires[0]);
      pcie.rx.status1_ext(rxstatus_wires[1]);
      pcie.rx.status2_ext(rxstatus_wires[2]);
      pcie.rx.status3_ext(rxstatus_wires[3]);
      pcie.rx.status4_ext(rxstatus_wires[4]);
      pcie.rx.status5_ext(rxstatus_wires[5]);
      pcie.rx.status6_ext(rxstatus_wires[6]);
      pcie.rx.status7_ext(rxstatus_wires[7]);
   endrule

   (* no_implicit_conditions *)
   rule pcie_rxvalid;
      pcie.rx.valid0_ext(rxvalid_wires[0]);
      pcie.rx.valid1_ext(rxvalid_wires[1]);
      pcie.rx.valid2_ext(rxvalid_wires[2]);
      pcie.rx.valid3_ext(rxvalid_wires[3]);
      pcie.rx.valid4_ext(rxvalid_wires[4]);
      pcie.rx.valid5_ext(rxvalid_wires[5]);
      pcie.rx.valid6_ext(rxvalid_wires[6]);
      pcie.rx.valid7_ext(rxvalid_wires[7]);
   endrule

   (* no_implicit_conditions *)
   rule pcie_phystatus;
      pcie.phystatus.ext(phystatus_wires[0]);
   endrule

   (* no_implicit_conditions *)
   rule power_mgmt;
      pcie.pm.auxpwr(0);
      pcie.pm.data(10'b0);
      pcie.pm_e.vent(0);
      pcie.pm.e_to_cr(0);
   endrule

   C2B c2b <- mkC2B(coreclk);
   rule pld_clk_rule;
      pcie.pld.clk(c2b.o());
   endrule

   method Clock coreclkout_hip;
      return coreclk;
   endmethod

   method Reset core_reset;
      return corerst;
   endmethod

   interface PcieLmi lmi;
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

   interface PcieMsi msi;
      method Bit#(1) int_ack;
         return pcie.app.int_ack;
      endmethod
      method Bit#(1) msi_ack;
         return pcie.app.msi_ack;
      endmethod
      method msi_num = pcie.app.msi_num;
      method msi_req = pcie.app.msi_req;
      method msi_tc  = pcie.app.msi_tc;
      method int_sts = pcie.app.int_sts;
      method pex_msi_num = pcie.pex_msi.num;
   endinterface

   interface PcieTlCfg tl_cfg;
      method Bit#(4) add();
         return pcie.tl_cfg.add;
      endmethod
      method Bit#(32) ctl();
         return pcie.tl_cfg.ctl;
      endmethod
      method Bit#(1) ctl_wr();
         return pcie.tl_cfg.ctl_wr;
      endmethod
      method Bit#(53) sts();
         return pcie.tl_cfg.sts;
      endmethod
      method Bit#(1) sts_wr();
         return pcie.tl_cfg.sts_wr;
      endmethod
      method cpl_pending = pcie.cpl.pending;
      method cpl_err = pcie.cpl.err;
   endinterface

   interface PcieRxSt rx_st;
      method Bit#(1)   sop();   return pcie.rx_st.sop0;   endmethod
      method Bit#(1)   eop();   return pcie.rx_st.eop0;   endmethod
      method Bit#(128) data();  return pcie.rx_st.data0;  endmethod
      method Bit#(1)   valid(); return pcie.rx_st.valid0; endmethod
      method Bit#(1)   err();   return pcie.rx_st.err0;   endmethod
      method Bit#(1)   empty(); return pcie.rx_st.empty0; endmethod
      method Bit#(8)   bar();   return pcie.rx_st.bardec0; endmethod
      method Bit#(16)  be();    return pcie.rx_st.be0; endmethod
      method ready = pcie.rx_st.ready0;
      method mask = pcie.rx_st.mask0;
   endinterface

   interface PcieTxSt tx_st;
      method Bit#(1) ready (); return pcie.tx_st.ready0; endmethod
      method sop   = pcie.tx_st.sop0    ;
      method eop   = pcie.tx_st.eop0    ;
      method valid = pcie.tx_st.valid0  ;
      method err   = pcie.tx_st.err0    ;
      method empty = pcie.tx_st.empty0  ;
      method data  = pcie.tx_st.data0   ;
   endinterface

   interface PcieRxin rx;
      method Action in(Vector#(8, Bit#(1)) a);
         writeVReg(rx_in_wires, a);
      endmethod
   endinterface

   interface PcieTxout tx;
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

   interface PcieHipPipe hip_pipe;
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

      method Action phystatus(Vector#(1, Bit#(1)) a);
         writeVReg(phystatus_wires, a);
      endmethod

      method rxpolarity();
         Vector#(8, Bit#(1)) retval;
         retval = unpack({pcie.rx.polarity7_ext,
                          pcie.rx.polarity6_ext,
                          pcie.rx.polarity5_ext,
                          pcie.rx.polarity4_ext,
                          pcie.rx.polarity3_ext,
                          pcie.rx.polarity2_ext,
                          pcie.rx.polarity1_ext,
                          pcie.rx.polarity0_ext});
         return retval;
      endmethod

      method txcompl();
         Vector#(8, Bit#(1)) retval;
         retval = unpack({pcie.tx.compl7_ext,
                          pcie.tx.compl6_ext,
                          pcie.tx.compl5_ext,
                          pcie.tx.compl4_ext,
                          pcie.tx.compl3_ext,
                          pcie.tx.compl2_ext,
                          pcie.tx.compl1_ext,
                          pcie.tx.compl0_ext});
         return retval;
      endmethod

      method txdata();
         Vector#(8, Bit#(8)) retval;
         retval = unpack({pcie.tx.data7_ext,
                          pcie.tx.data6_ext,
                          pcie.tx.data5_ext,
                          pcie.tx.data4_ext,
                          pcie.tx.data3_ext,
                          pcie.tx.data2_ext,
                          pcie.tx.data1_ext,
                          pcie.tx.data0_ext});
         return retval;
      endmethod

      method txdatak();
         Vector#(8, Bit#(1)) retval;
         retval = unpack({pcie.tx.datak7_ext,
                          pcie.tx.datak6_ext,
                          pcie.tx.datak5_ext,
                          pcie.tx.datak4_ext,
                          pcie.tx.datak3_ext,
                          pcie.tx.datak2_ext,
                          pcie.tx.datak1_ext,
                          pcie.tx.datak0_ext});
         return retval;
      endmethod

      method txdetectrx();
         Vector#(1, Bit#(1)) retval;
         retval = unpack(pcie.tx.detectrx_ext);
         return retval;
      endmethod

      method txelecidle();
         Vector#(8, Bit#(1)) retval;
         retval = unpack({pcie.tx.elecidle7_ext,
                          pcie.tx.elecidle6_ext,
                          pcie.tx.elecidle5_ext,
                          pcie.tx.elecidle4_ext,
                          pcie.tx.elecidle3_ext,
                          pcie.tx.elecidle2_ext,
                          pcie.tx.elecidle1_ext,
                          pcie.tx.elecidle0_ext});
         return retval;
      endmethod

      method powerdown();
         Vector#(1, Bit#(2)) retval;
         retval = unpack(pcie.powerdown.ext);
         return retval;
      endmethod

      method sim_pipe_pclk_in = pcie.pclk.in;

      method sim_ltssmstate();
         return pcie.lts.sm;
      endmethod

      method sim_pipe_rate();
         return pcie.rate.ext;
      endmethod
   endinterface

   interface PcieHipCtrl hip_ctrl;
      method test_in = pcie.test.in;
      method simu_mode_pipe = pcie.pipe.mode;
   endinterface

   interface PcieHipRst hip_rst;
      method Bit#(1) serdes_pll_locked;
         return pcie.rc_pll.locked;
      endmethod

      method reconfig_clk_locked = pcie.reconfig.clk_locked;
   endinterface

   interface PcieTxCred tx_cred;
      method cred();
         return pcie.tx.cred0;
      endmethod
   endinterface

endmodule
