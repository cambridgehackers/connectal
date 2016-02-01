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

import FIFOF             ::*;
import Probe             ::*;

import Pipe              ::*;

typedef enum {
   PcieCfg_none,
   PcieCfg_current_speed,
   PcieCfg_dpa_substate_change,
   PcieCfg_err_cor_out,
   PcieCfg_err_fatal_out,
   PcieCfg_err_nonfatal_out,
   PcieCfg_flr_in_process,
   PcieCfg_function_power_state,
   PcieCfg_function_status,
   PcieCfg_hot_reset_out,
   PcieCfg_link_power_state,
   PcieCfg_ltr_enable,
   PcieCfg_ltssm_state,
   PcieCfg_max_payload,
   PcieCfg_max_read_req,
   PcieCfg_negotiated_width,
   PcieCfg_obff_enable,
   PcieCfg_phy_link_down,
   PcieCfg_phy_link_status,
   PcieCfg_pl_status_change,
   PcieCfg_power_state_change_interrupt,
   PcieCfg_rcb_status,
   PcieCfg_rq_backpressure,
   PcieCfg_initial_link_width,
   PcieCfg_lane_reversal_mode,
   PcieCfg_phy_link_up,
   PcieCfg_received_hot_rst,
   PcieCfg_rx_pm_state,
   PcieCfg_sel_lnk_rate,
   PcieCfg_tx_pm_state,
   PcieCfg_link_gen2_cap,
   PcieCfg_link_partner_gen2_supported,
   PcieCfg_link_up
   } PcieCfgType deriving (Bits,Eq);

typedef struct {
   Bit#(32) timestamp;
   Bit#(8) src;
   Bit#(24) value;
} RegChange deriving (Bits);

module mkChangeSource#(Reg#(Bit#(32)) cyclesReg, Tuple2#(PcieCfgType,Bit#(24)) tpl)(PipeOut#(RegChange));
   match { .src, .v } = tpl;
   Reg#(Bit#(24))    snapshot <- mkReg(0);
   FIFOF#(RegChange) changeFifo <- mkFIFOF1();
   rule rl_update if (v != snapshot);
      if (changeFifo.notFull) begin
	 changeFifo.enq(RegChange { timestamp: cyclesReg, src: extend(pack(src)), value: extend(v) });
	 snapshot <= v;
      end
   endrule
   return toPipeOut(changeFifo);
endmodule
