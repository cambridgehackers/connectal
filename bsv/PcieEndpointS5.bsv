// Copyright (c) 2014 xxx
// Filename      : PcieEndpointS5.bsv
// Description   :
package PcieEndpointS5;

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
import PCIE              ::*;
import PCIEWRAPPER       ::*;
import Bufgctrl           ::*;
import PcieGearbox       :: *;

(* always_ready, always_enabled *)
interface PcieWrap;
    interface PciewrapApp           app;
    interface PciewrapCfg           cfg;
    interface PciewrapCoreclkout    coreclkout;
    interface PciewrapCpl           cpl;
    interface PciewrapHpg           hpg;
    interface PciewrapInt           int;
    interface PciewrapKo            ko;
    interface PciewrapLmi           lmi;
    interface PciewrapReconfig      reconfig;
    interface PciewrapReset         reset;
    interface PciewrapRx            rx;
    interface PciewrapRx_st         rx_st;
    interface PciewrapTl            tl;
    interface PciewrapTx            tx;
    interface PciewrapTx_st         tx_st;
endinterface
import "BVI" altera_pcie_sv_hip_ast =
module vMkAlteraS5PCIExpress#(PCIEParams params, Clock pld_clk)(PCIE_S5#(lanes))
   provisos( Add#(1, z, lanes));
   let pld_clk_reset <- exposeCurrentReset;

   default_clock clk(pld_clk); // 100 MHz refclk
   default_reset rstn(pld_clk_reset) = pld_clk_reset;
   input_reset pin_perst(pin_perst) = pin_perst;
   input_clock pld_clk(pld_clk) = pld_clk;
   input_reset pld_clk_reset() = pld_clk_reset; /* from clock*/

   interface PciewrapApp app;
      method appint_ack    int_ack();
      method               int_sts(appint_sts) enable((*inhigh*) EN_appint_sts);
      method appmsi_ack    msi_ack();
      method               msi_num(appmsi_num) enable((*inhigh*) EN_appmsi_num);
      method               msi_req(appmsi_req) enable((*inhigh*) EN_appmsi_req);
      method               msi_tc(appmsi_tc) enable((*inhigh*) EN_appmsi_tc);
   endinterface

   interface PciewrapCfg cfg;
      method cfg_par_err   par_err();
   endinterface

   interface PciewrapCoreclkout     coreclkout;
      output_clock         hip(coreclkout_hip);
   endinterface

   interface PciewrapCpl cpl;
      method               err(cpl_err) enable((*inhigh*) EN_cpl_err);
      method               pending(cpl_pending) enable((*inhigh*) EN_cpl_pending);
   endinterface

   interface PciewrapHpg hpg;
      method               ctrler(hpg_ctrler) enable((*inhigh*) EN_hpg_ctrler);
   endinterface

   interface PciewrapInt int;
      method int_status    status();
   endinterface

   interface PciewrapKo ko;
      method ko_cpl_spc_data     cpl_spc_data();
      method ko_cpl_spc_header   cpl_spc_header();
   endinterface

   interface PciewrapLmi lmi;
      method lmiack        ack();
      method               addr(lmiaddr) enable((*inhigh*) EN_lmiaddr);
      method               din(lmidin) enable((*inhigh*) EN_lmidin);
      method lmidout       dout();
      method               rden(lmirden) enable((*inhigh*) EN_lmirden);
      method               wren(lmiwren) enable((*inhigh*) EN_lmiwren);
   endinterface

   interface PciewrapReconfig     reconfig;
      method reconfig_from_xcvr  from_xcvr();
      method                     to_xcvr(reconfig_to_xcvr) enable((*inhigh*) EN_reconfig_to_xcvr);
   endinterface

   interface PciewrapReset     reset;
      output_reset status(reset_status);
   endinterface

   interface PciewrapRx     rx;
      method in0(rxin0) enable((*inhigh*) EN_rxin0);
      method in1(rxin1) enable((*inhigh*) EN_rxin1);
      method in2(rxin2) enable((*inhigh*) EN_rxin2);
      method in3(rxin3) enable((*inhigh*) EN_rxin3);
      method in4(rxin4) enable((*inhigh*) EN_rxin4);
      method in5(rxin5) enable((*inhigh*) EN_rxin5);
      method in6(rxin6) enable((*inhigh*) EN_rxin6);
      method in7(rxin7) enable((*inhigh*) EN_rxin7);
      method rxpar_err par_err();
   endinterface

   interface PciewrapRx_st     rx_st;
      method rx_stbar bar();
      method rx_stdata data();
      method rx_stempty empty();
      method rx_steop eop();
      method rx_sterr err();
      method mask(rx_stmask) enable((*inhigh*) EN_rx_stmask);
      method ready(rx_stready) enable((*inhigh*) EN_rx_stready);
      method rx_stsop sop();
      method rx_stvalid valid();
   endinterface

   interface PciewrapTl     tl;
      method tlcfg_add cfg_add();
      method tlcfg_ctl cfg_ctl();
      method tlcfg_sts cfg_sts();
   endinterface

   interface PciewrapTx     tx;
      method txout0 out0();
      method txout1 out1();
      method txout2 out2();
      method txout3 out3();
      method txout4 out4();
      method txout5 out5();
      method txout6 out6();
      method txout7 out7();
      method txpar_err par_err();
   endinterface

   interface PciewrapTx_st     tx_st;
      method            data(tx_stdata) enable((*inhigh*) EN_tx_stdata);
      method            empty(tx_stempty) enable((*inhigh*) EN_tx_stempty);
      method            eop(tx_steop) enable((*inhigh*) EN_tx_steop);
      method            err(tx_sterr) enable((*inhigh*) EN_tx_sterr);
      method tx_stready ready();
      method            sop(tx_stsop) enable((*inhigh*) EN_tx_stsop);
      method            valid(tx_stvalid) enable((*inhigh*) EN_tx_stvalid);
   endinterface

   schedule (app.int_ack, app.int_sts, app.msi_ack, app.msi_num, app.msi_req, app.msi_tc, cfg.par_err, cpl.err, cpl.pending, hpg.ctrler, int.status, ko.cpl_spc_data, ko.cpl_spc_header, lmi.ack, lmi.addr, lmi.din, lmi.dout, lmi.rden, lmi.wren, reconfig.from_xcvr, reconfig.to_xcvr, rx.in0, rx.in1, rx.in2, rx.in3, rx.in4, rx.in5, rx.in6, rx.in7, rx.par_err, rx_st.bar, rx_st.data, rx_st.empty, rx_st.eop, rx_st.err, rx_st.mask, rx_st.ready, rx_st.sop, rx_st.valid, tl.cfg_add, tl.cfg_ctl, tl.cfg_sts, tx.out0, tx.out1, tx.out2, tx.out3, tx.out4, tx.out5, tx.out6, tx.out7, tx.par_err, tx_st.data, tx_st.empty, tx_st.eop, tx_st.err, tx_st.ready, tx_st.sop, tx_st.valid) CF (app.int_ack, app.int_sts, app.msi_ack, app.msi_num, app.msi_req, app.msi_tc, cfg.par_err, cpl.err, cpl.pending, hpg.ctrler, int.status, ko.cpl_spc_data, ko.cpl_spc_header, lmi.ack, lmi.addr, lmi.din, lmi.dout, lmi.rden, lmi.wren, reconfig.from_xcvr, reconfig.to_xcvr, rx.in0, rx.in1, rx.in2, rx.in3, rx.in4, rx.in5, rx.in6, rx.in7, rx.par_err, rx_st.bar, rx_st.data, rx_st.empty, rx_st.eop, rx_st.err, rx_st.mask, rx_st.ready, rx_st.sop, rx_st.valid, tl.cfg_add, tl.cfg_ctl, tl.cfg_sts, tx.out0, tx.out1, tx.out2, tx.out3, tx.out4, tx.out5, tx.out6, tx.out7, tx.par_err, tx_st.data, tx_st.empty, tx_st.eop, tx_st.err, tx_st.ready, tx_st.sop, tx_st.valid);

endmodule: vMkAlteraS5PCIExpress

////////////////////////////////////////////////////////////////////////////////
/// Interfaces
////////////////////////////////////////////////////////////////////////////////

interface PcieEndpointS5#(numeric type lanes);
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

`ifdef BOARD_de5
typedef 8 PcieLanes;
typedef 8 NumLeds;
`endif

(* synthesize *)
module mkPcieEndpointS5(PcieEndpointS5#(PcieLanes));

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

   PCIE_S5#(PcieLanes) pcie_ep <- vMkAlteraS5PCIExpress(params, clockGen.clkout0, clockGen.clkout2, bbufc.o);

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
endmodule: mkPcieEndpointS5

endpackage: PcieEndpointS5
