////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2012  Bluespec, Inc.  ALL RIGHTS RESERVED.
////////////////////////////////////////////////////////////////////////////////
//  Filename      : ConnectalXilinx7PCIE.bsv
//  Description   :
////////////////////////////////////////////////////////////////////////////////

import ConnectalConfig   ::*;
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
import PCIEWRAPPER       ::*;
import Bufgctrl           ::*;
import PcieGearbox       :: *;
import PcieStateChanges  ::*;
import Pipe              :: *;

`include "ConnectalProjectConfig.bsv"

(* always_ready, always_enabled *)
interface PCIE_X7#(numeric type lanes);
   interface PciewrapPci_exp#(lanes)   pcie;
   interface PciewrapUser#(lanes)      user;
   interface PciewrapFc#(lanes)        fc;
   interface PciewrapTx#(lanes)        tx;
   interface PciewrapS_axis_tx#(lanes) s_axis_tx;
   interface PciewrapM_axis_rx#(lanes) m_axis_rx;
   interface PciewrapRx#(lanes)        rx;
   interface PciewrapCfg#(lanes)       cfg;
   method    Action                    cfg_dsn(Bit#(64) i);
   interface Clock                     pipe_txoutclk_out;
   method    Action                    pipe_mmcm_lock_in(Bit#(1) v);
   method    Bit#(lanes)               pipe_pclk_sel_out();
endinterface

import "BVI" pcie_7x_0 =
module vMkXilinx7PCIExpress#(PCIEParams params, Clock clk_125mhz, Clock pipe_userclk1_in, Clock pclk_in)(PCIE_X7#(lanes))
   provisos( Add#(1, z, lanes));
   let sys_rst_n <- exposeCurrentReset;

   default_clock clk(sys_clk); // 100 MHz refclk
   default_reset rstn(sys_rst_n) = sys_rst_n;
   input_clock clk_125mhz(pipe_dclk_in) = clk_125mhz;
   input_clock clk_oobclk_in(pipe_oobclk_in) = clk_125mhz;
   input_clock pipe_userclk1_in(pipe_userclk1_in) = pipe_userclk1_in;
   input_clock pipe_userclk2_in(pipe_userclk2_in) = pipe_userclk1_in;
   input_clock pclk_in(pipe_pclk_in) = pclk_in;
   input_clock pclk_usrin(pipe_rxusrclk_in) = pclk_in;
   method pipe_mmcm_lock_in(pipe_mmcm_lock_in) enable((*inhigh*)en_pipe_mmcm_lock_in);
   method pipe_pclk_sel_out pipe_pclk_sel_out   clocked_by(pclk_in);

   interface PciewrapPci_exp pcie;
      method                  rxp(pci_exp_rxp) enable((*inhigh*)en0)    reset_by(no_reset);
      method                  rxn(pci_exp_rxn) enable((*inhigh*)en1)    reset_by(no_reset);
      method pci_exp_txp      txp    reset_by(no_reset);
      method pci_exp_txn      txn    reset_by(no_reset);
   endinterface

   interface PciewrapUser     user;
      output_clock            clk_out(user_clk_out);
      output_reset            reset_out(user_reset_out);
      method user_lnk_up      lnk_up   clocked_by(no_clock) reset_by(no_reset); /* semi-static */
      method user_app_rdy     app_rdy   clocked_by(no_clock) reset_by(no_reset);
   endinterface
    interface PciewrapFc     fc;
      method fc_ph            ph   clocked_by(user_clk_out)    reset_by(no_reset);
      method fc_pd            pd   clocked_by(user_clk_out)    reset_by(no_reset);
      method fc_nph           nph   clocked_by(user_clk_out)    reset_by(no_reset);
      method fc_npd           npd   clocked_by(user_clk_out)    reset_by(no_reset);
      method fc_cplh          cplh   clocked_by(user_clk_out)    reset_by(no_reset);
      method fc_cpld          cpld   clocked_by(user_clk_out)    reset_by(no_reset);
      method                  sel(fc_sel)    enable((*inhigh*)en01)   clocked_by(user_clk_out)    reset_by(no_reset);
   endinterface

   interface PciewrapTx     tx;
      method tx_buf_av        buf_av   clocked_by(user_clk_out)    reset_by(no_reset);
      method tx_err_drop      err_drop   clocked_by(user_clk_out)    reset_by(no_reset);
      method tx_cfg_req       cfg_req   clocked_by(user_clk_out)    reset_by(no_reset);
      method                  cfg_gnt(tx_cfg_gnt)    enable((*inhigh*)en07)   clocked_by(user_clk_out)    reset_by(no_reset);
   endinterface

    interface PciewrapS_axis_tx     s_axis_tx;
      method                  tlast(s_axis_tx_tlast)    enable((*inhigh*)en02)   clocked_by(user_clk_out)    reset_by(no_reset);
      method                  tdata(s_axis_tx_tdata)    enable((*inhigh*)en03)   clocked_by(user_clk_out)    reset_by(no_reset);
      method                  tkeep(s_axis_tx_tkeep)    enable((*inhigh*)en04)   clocked_by(user_clk_out)    reset_by(no_reset);
      method                  tvalid(s_axis_tx_tvalid)    enable((*inhigh*)en05)   clocked_by(user_clk_out)    reset_by(no_reset);
      method                  tuser(s_axis_tx_tuser)    enable((*inhigh*)en06)   clocked_by(user_clk_out)    reset_by(no_reset);
      method s_axis_tx_tready tready   clocked_by(user_clk_out)    reset_by(no_reset);
   endinterface

    interface PciewrapM_axis_rx     m_axis_rx;
      method m_axis_rx_tlast  tlast   clocked_by(user_clk_out)    reset_by(no_reset);
      method m_axis_rx_tdata  tdata   clocked_by(user_clk_out)    reset_by(no_reset);
      method m_axis_rx_tkeep  tkeep   clocked_by(user_clk_out)    reset_by(no_reset);
      method m_axis_rx_tuser  tuser   clocked_by(user_clk_out)    reset_by(no_reset);
      method m_axis_rx_tvalid tvalid   clocked_by(user_clk_out)    reset_by(no_reset);
      method                  tready(m_axis_rx_tready)    enable((*inhigh*)en08)   clocked_by(user_clk_out)    reset_by(no_reset);
   endinterface
   interface PciewrapRx     rx;
      method                  np_ok(rx_np_ok)    enable((*inhigh*)en09)   clocked_by(user_clk_out)    reset_by(no_reset);
      method                  np_req(rx_np_req)    enable((*inhigh*)en10)   clocked_by(user_clk_out)    reset_by(no_reset);
   endinterface

   method                    cfg_dsn(cfg_dsn)    enable((*inhigh*)en25)   clocked_by(user_clk_out);

   interface PciewrapCfg     cfg;
      method cfg_bus_number      bus_number   clocked_by(no_clock) reset_by(no_reset);
      method cfg_device_number   device_number   clocked_by(no_clock) reset_by(no_reset);
      method cfg_function_number function_number   clocked_by(no_clock) reset_by(no_reset);
      method cfg_lcommand        lcommand   clocked_by(user_clk_out) reset_by(no_reset);
      method                     interrupt(cfg_interrupt)    enable((*inhigh*)en32)   clocked_by(user_clk_out) reset_by(no_reset);

      method cfg_bridge_serr_en bridge_serr_en();
      method cfg_command command();
      method cfg_dcommand dcommand();
      method cfg_dcommand2 dcommand2();
      method cfg_lstatus lstatus();
      method cfg_pcie_link_state pcie_link_state();
      method pciecap_interrupt_msgnum(cfg_pciecap_interrupt_msgnum) enable((*inhigh*) EN_cfg_pciecap_interrupt_msgnum);
      method cfg_received_func_lvl_rst received_func_lvl_rst();
      method cfg_slot_control_electromech_il_ctl_pulse slot_control_electromech_il_ctl_pulse();
      method cfg_status status();
      method cfg_to_turnoff to_turnoff();
      method trn_pending(cfg_trn_pending) enable((*inhigh*) EN_cfg_trn_pending);
      method turnoff_ok(cfg_turnoff_ok) enable((*inhigh*) EN_cfg_turnoff_ok);
      method cfg_vc_tcvc_map vc_tcvc_map();
   endinterface

   output_clock pipe_txoutclk_out(pipe_txoutclk_out);

   schedule (user_lnk_up, user_app_rdy, fc_ph, fc_pd, fc_nph, fc_npd, fc_cplh, fc_cpld, fc_sel, s_axis_tx_tlast,
	     s_axis_tx_tdata, s_axis_tx_tkeep, s_axis_tx_tvalid, s_axis_tx_tready, s_axis_tx_tuser, tx_buf_av, tx_err_drop,
	     tx_cfg_req, tx_cfg_gnt, m_axis_rx_tlast, m_axis_rx_tdata, m_axis_rx_tkeep, m_axis_rx_tuser, m_axis_rx_tvalid,
	     m_axis_rx_tready, rx_np_ok, rx_np_req,
	     cfg_bus_number, cfg_device_number, cfg_function_number, cfg_lcommand,
cfg_command, cfg_dcommand, cfg_dcommand2, cfg_lstatus, cfg_pcie_link_state, cfg_received_func_lvl_rst, cfg_status, cfg_to_turnoff, cfg_vc_tcvc_map,
cfg_bridge_serr_en, cfg_slot_control_electromech_il_ctl_pulse,
cfg_pciecap_interrupt_msgnum, cfg_trn_pending, cfg_turnoff_ok,
cfg_interrupt, cfg_dsn,
	     pcie_txp, pcie_txn, pcie_rxp, pcie_rxn, pipe_mmcm_lock_in, pipe_pclk_sel_out
	     ) CF
            (user_lnk_up, user_app_rdy, fc_ph, fc_pd, fc_nph, fc_npd, fc_cplh, fc_cpld, fc_sel, s_axis_tx_tlast,
	     s_axis_tx_tdata, s_axis_tx_tkeep, s_axis_tx_tvalid, s_axis_tx_tready, s_axis_tx_tuser, tx_buf_av, tx_err_drop,
	     tx_cfg_req, tx_cfg_gnt, m_axis_rx_tlast, m_axis_rx_tdata, m_axis_rx_tkeep, m_axis_rx_tuser, m_axis_rx_tvalid,
	     m_axis_rx_tready, rx_np_ok, rx_np_req,
	     cfg_bus_number, cfg_device_number, cfg_function_number, cfg_lcommand,
cfg_command, cfg_dcommand, cfg_dcommand2, cfg_lstatus, cfg_pcie_link_state, cfg_received_func_lvl_rst, cfg_status, cfg_to_turnoff, cfg_vc_tcvc_map,
cfg_bridge_serr_en, cfg_slot_control_electromech_il_ctl_pulse,
cfg_pciecap_interrupt_msgnum, cfg_trn_pending, cfg_turnoff_ok,
cfg_interrupt, cfg_dsn,
	     pcie_txp, pcie_txn, pcie_rxp, pcie_rxn, pipe_mmcm_lock_in, pipe_pclk_sel_out
             );

endmodule: vMkXilinx7PCIExpress

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
   Bit#(8)       keep;
   Bit#(64)      data;
} AxiRx deriving (Bits, Eq);

typedef struct {
   Bit#(1)       last;
   Bit#(8)       keep;
   Bit#(64)      data;
} AxiTx deriving (Bits, Eq);

(* synthesize *)
module mkPcieEndpointX7(PcieEndpointX7#(PcieLanes));

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

   PCIE_X7#(PcieLanes) pcie_ep <- vMkXilinx7PCIExpress(params, clockGen.clkout0, clockGen.clkout2, bbufc.o);
   //new PcieWrap#(PcieLanes)  pciew <- mkPcieWrap();

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
   clkgenParams.clkout0_divide_f = derivedClockPeriod;
   clkgenParams.clkout1_divide     = round(mainClockPeriod); // defaults to 125MHz;
   clkgenParams.clkout1_duty_cycle = 0.5;
   clkgenParams.clkout1_phase      = 0.0000;
   ClockGenerator7           clkgen <- mkClockGenerator7(clkgenParams, clocked_by clock250, reset_by user_reset_n);
   Clock clock125 = clkgen.clkout1; /* 125MHz user_clk */
   Reset reset125 <- mkAsyncReset(4, user_reset_n, clock125);
   Clock derivedClock = clkgen.clkout0;
   Reset derivedReset <- mkAsyncReset(4, user_reset_n, derivedClock);

   FIFOF#(RegChange) changeFifo <- mkFIFOF(clocked_by clock125, reset_by reset125); //mkSizedBRAMFIFOF(128, clocked_by clock125, reset_by reset125);

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
   interface regChanges = mapPipe(pack, toPipeOut(changeFifo));
   interface Clock epPcieClock = clock125;
   interface Reset epPcieReset = reset125;
   interface Clock epPortalClock = portalClock;
   interface Reset epPortalReset = portalReset;
   interface Clock epDerivedClock = derivedClock;
   interface Reset epDerivedReset = derivedReset;
endmodule: mkPcieEndpointX7

