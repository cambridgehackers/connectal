////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2012  Bluespec, Inc.  ALL RIGHTS RESERVED.
////////////////////////////////////////////////////////////////////////////////
//  Filename      : XbsvXilinx7PCIE.bsv
//  Description   :
////////////////////////////////////////////////////////////////////////////////
package XbsvXilinx7Pcie;

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

import XbsvXilinxCells   ::*;
import XilinxCells       ::*;
import PCIE              ::*;
import PCIEWRAPPER       ::*;
import Bufgctrl           ::*;

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
module vMkXilinx7PCIExpress#(PCIEParams params, Clock clk_125mhz, Clock clkout2, Clock pclk_in)(PCIE_X7#(lanes))
   provisos( Add#(1, z, lanes));
   let sys_rst_n <- exposeCurrentReset;

   default_clock clk(sys_clk); // 100 MHz refclk
   default_reset rstn(sys_rst_n) = sys_rst_n;
   input_clock clk_125mhz(pipe_dclk_in) = clk_125mhz;
   input_clock clk_oobclk_in(pipe_oobclk_in) = clk_125mhz;
   input_clock clkout2(pipe_userclk1_in) = clkout2;
   input_clock clkout2user(pipe_userclk2_in) = clkout2;
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
      output_reset    reset_out(user_reset_out);
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
interface PCIE_TRN_COMMON_X7;
   interface Clock       clk;
   interface Clock       clk2;
   interface Reset       reset_n;
   method    Bit#(1)     link_up;
   method    Bit#(1)     app_ready;
endinterface

interface PCIExpressX7#(numeric type lanes);
   interface PciewrapPci_exp#(lanes)   pcie;
   interface PCIE_TRN_COMMON_X7 trn;
   method    Action      xmit(TLPData#(8) data);
   method    ActionValue#(Tuple3#(Bool, Bool, TLPData#(8))) recv();
   interface ReadOnly#(PciId)   pciId;
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

module mkPCIExpressEndpointX7#(PCIEParams params)(PCIExpressX7#(lanes))
   provisos(Add#(1, z, lanes));

   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   B2C1 b2c <- mkB2C1();
   ClockGenerator7AdvParams   clockParams = defaultValue;
   clockParams.bandwidth          = "OPTIMIZED";
   clockParams.compensation       = "INTERNAL"; //ZHOLD
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
   clockParams.clkout3_divide     = 4;
   clockParams.clkout3_duty_cycle = 0.5;
   clockParams.clkout3_phase      = 0.0000;
   clockParams.clkout4_divide     = 20;
   clockParams.clkout4_duty_cycle = 0.5;
   clockParams.clkout4_phase      = 0.0000;
   clockParams.divclk_divide      = 1;
   clockParams.ref_jitter1        = 0.010;

   clockParams.clkin_buffer = False;
   clockParams.clkout0_buffer = True;
   clockParams.clkout2_buffer = True;
   XClockGenerator7   clockGen <- mkClockGenerator7Adv(clockParams, clocked_by b2c.c);
   C2B c2b_fb <- mkC2B(clockGen.clkfbout, clocked_by clockGen.clkfbout);
   rule txoutrule5;
      clockGen.clkfbin(c2b_fb.o());
   endrule

   Reset defaultReset <- exposeCurrentReset();
   Bufgctrl bbufc <- mkBufgctrl(clockGen.clkout0, defaultReset, clockGen.clkout1, defaultReset);
   Reset rsto <- mkAsyncReset(2, defaultReset, bbufc.o);
   Reg#(Bit#(1)) pclk_sel <- mkReg(0, clocked_by bbufc.o, reset_by rsto);
   Reg#(Bit#(lanes)) pclk_sel_reg1 <- mkReg(0, clocked_by bbufc.o, reset_by rsto);
   Reg#(Bit#(lanes)) pclk_sel_reg2 <- mkReg(0, clocked_by bbufc.o, reset_by rsto);

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

   PCIE_X7#(lanes) pcie_ep <- vMkXilinx7PCIExpress(params, clockGen.clkout0, clockGen.clkout2, bbufc.o);
   //new PcieWrap#(lanes)  pciew <- mkPcieWrap();
   Clock txoutclk_buf <- mkClockBUFG(clocked_by pcie_ep.pipe_txoutclk_out);
   C2B c2b <- mkC2B(txoutclk_buf);
   rule txoutrule;
      b2c.inputclock(c2b.o());
   endrule
   rule lockedrule;
      pcie_ep.pipe_mmcm_lock_in(pack(clockGen.locked));
   endrule

   rule selr3;
      pclk_sel_reg1 <= pcie_ep.pipe_pclk_sel_out();
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

   Clock                     user_clk             = pcie_ep.user.clk_out;
   Reset                     user_reset_n        <- mkResetInverter(pcie_ep.user.reset_out);
   Wire#(Bit#(1))            wDiscontinue        <- mkDWire(0,   clocked_by user_clk, reset_by noReset);
   Wire#(Bit#(1))            wEcrcGen            <- mkDWire(0,   clocked_by user_clk, reset_by noReset);
   Wire#(Bit#(1))            wErrFwd             <- mkDWire(0,   clocked_by user_clk, reset_by noReset);
   Wire#(Bit#(1))            wCutThrough         <- mkDWire(0,   clocked_by user_clk, reset_by noReset);
   Wire#(Bit#(1))            wAxiTxValid         <- mkDWire(0,   clocked_by user_clk, reset_by noReset);
   Wire#(Bit#(1))            wAxiTxLast          <- mkDWire(0,   clocked_by user_clk, reset_by noReset);
   Wire#(Bit#(64))           wAxiTxData          <- mkDWire(0,   clocked_by user_clk, reset_by noReset);
   Wire#(Bit#(8))            wAxiTxKeep          <- mkDWire(0,   clocked_by user_clk, reset_by noReset);
   FIFO#(AxiTx)              fAxiTx              <- mkBypassFIFO(clocked_by user_clk, reset_by noReset);
   FIFOF#(AxiRx)             fAxiRx              <- mkBypassFIFOF(clocked_by user_clk, reset_by noReset);

   ClockGenerator7Params     params               = defaultValue;
   params.clkin1_period    = 4.000;
   params.clkin_buffer     = False;
   params.clkfbout_mult_f  = 4.000;
   params.clkout0_divide_f = 8.000;
   ClockGenerator7           clkgen              <- mkClockGenerator7(params,   clocked_by user_clk, reset_by user_reset_n);

   ////////////////////////////////////////////////////////////////////////////////
   /// Rules
   ////////////////////////////////////////////////////////////////////////////////
   (* fire_when_enabled, no_implicit_conditions *)
   rule others;
      pcie_ep.fc.sel(0 /*RECEIVE_BUFFER_AVAILABLE_SPACE*/);
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_tx;
      pcie_ep.s_axis_tx.tuser({ wDiscontinue, wCutThrough, wErrFwd, wEcrcGen });
      pcie_ep.s_axis_tx.tvalid(wAxiTxValid);
      pcie_ep.s_axis_tx.tlast(wAxiTxLast);
      pcie_ep.s_axis_tx.tdata(wAxiTxData);
      pcie_ep.s_axis_tx.tkeep(wAxiTxKeep);
   endrule

   (* fire_when_enabled *)
   rule drive_axi_tx_info if (pcie_ep.s_axis_tx.tready != 0);
      let info <- toGet(fAxiTx).get;
      wAxiTxValid <= 1;
      wAxiTxLast  <= info.last;
      wAxiTxData  <= info.data;
      wAxiTxKeep  <= info.keep;
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule drive_axi_rx_ready;
      pcie_ep.m_axis_rx.tready(pack(fAxiRx.notFull));
   endrule

   (* fire_when_enabled *)
   rule sink_axi_rx if (pcie_ep.m_axis_rx.tvalid != 0);
      fAxiRx.enq(AxiRx {user: pcie_ep.m_axis_rx.tuser,
                        last: pcie_ep.m_axis_rx.tlast,
                        keep: pcie_ep.m_axis_rx.tkeep,
                        data: pcie_ep.m_axis_rx.tdata });
   endrule

   rule dsnrule;
      pcie_ep.cfg_dsn({ 32'h0000_0001, {{ 8'h1 } , 24'h000A35 }});
   endrule

   (* no_implicit_conditions, fire_when_enabled *)
   rule every1;
      pcie_ep.rx.np_ok(1);
      pcie_ep.rx.np_req(1);
   endrule
   (* no_implicit_conditions, fire_when_enabled *)
   rule every;
      wDiscontinue._write(0);
      wEcrcGen._write(0);
      wErrFwd._write(0);
      wCutThrough._write(0);
      pcie_ep.tx.cfg_gnt(1);
   endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface pcie = pcie_ep.pcie;

   interface PCIE_TRN_COMMON_X7 trn;
      interface clk     = user_clk;
      interface clk2    = clkgen.clkout0; /* half speed user_clk */
      interface reset_n = user_reset_n;
      method    link_up = pcie_ep.user.lnk_up;
      method    app_ready = pcie_ep.user.app_rdy;
   endinterface

      method Action xmit(data);
	 fAxiTx.enq(AxiTx {last: pack(data.eof),
                           keep: dwordSwap64BE(data.be),
                           data: dwordSwap64(data.data) });
      endmethod

      method ActionValue#(Tuple3#(Bool, Bool, TLPData#(8))) recv();
	 let info <- toGet(fAxiRx).get;
	 TLPData#(8) retval = defaultValue;
	 retval.sof  = (info.user[14] == 1);
	 retval.eof  = info.last != 0;
	 retval.hit  = info.user[8:2];
	 retval.be   = dwordSwap64BE(info.keep);
	 retval.data = dwordSwap64(info.data);
	 return tuple3(info.user[1] == 1, info.user[0] == 1, retval);
      endmethod

   interface ReadOnly pciId;
      method PciId _read();
         return PciId { bus:  pcie_ep.cfg.bus_number(),
	    dev: pcie_ep.cfg.device_number(), func: pcie_ep.cfg.function_number()};
      endmethod
   endinterface
endmodule: mkPCIExpressEndpointX7

endpackage: XbsvXilinx7Pcie
