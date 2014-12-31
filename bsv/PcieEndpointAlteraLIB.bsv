
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

(* always_ready, always_enabled *)
interface AlteraPcieHipRs;
(* prefix="", result="dlup_exit" *)   method Action dlup_exit(Bit#(1) dlup_exit);
(* prefix="", result="hotrst_exit" *) method Action hotrst_exit(Bit#(1) hotrst_exit);
(* prefix="", result="l2_exit" *)     method Action l2_exit(Bit#(1) l2_exit);
(* prefix="", result="ltssm" *)       method Action ltssm(Bit#(5) ltssm);
(* prefix="", result="test_sim" *)    method Action test_sim(Bit#(1) test_sim);
   method Bit#(1) app_rstn;
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
   Reg #(Bit#(1)) app_rstn0         <- mkReg(0, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));
   Reg #(Bit#(5)) ltssm_r           <- mkReg(0, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));
   Reg #(Bit#(1)) dlup_exit_r       <- mkReg(1, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));
   Reg #(Bit#(1)) hotrst_exit_r     <- mkReg(1, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));
   Reg #(Bit#(1)) l2_exit_r         <- mkReg(1, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));
   Reg #(Bit#(11)) rsnt_cntn        <- mkReg(0, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));
   Reg #(Bit#(23)) recovery_cnt     <- mkReg(0, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));
   Reg #(Bit#(1)) recovery_rst      <- mkReg(0, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));
   Reg #(Bit#(1)) exits_r           <- mkReg(0, clocked_by(pld_clk), reset_by(npor_sync_pld_clk));

   rule exit_v ((l2_exit_r == 1'b0) || (hotrst_exit_r == 1'b0) || (dlup_exit_r == 1'b0) || (ltssm_r == pack(LTSSM_DIS)) || (recovery_rst == 1'b1));
      exits_r <= 1'b1;
   endrule

   //Delay HIP reset upon npor
   rule delay_hip0 if (exits_r == 1'b1);
      rsnt_cntn <= 11'h3f0;
      app_rstn0 <= 1'b0;
   endrule

   rule delay_hip1 if (exits_r != 1'b1);
      rsnt_cntn <= rsnt_cntn + 11'h1;
   endrule

   rule delay_hip2 if ((exits_r != 1'b1) && (rsnt_cntn == pack(RSTN_CNT_MAX)));
      app_rstn0 <= 1'b1;
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
      return app_rstn0;
   endmethod
endmodule

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
