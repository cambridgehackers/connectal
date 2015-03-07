// megafunction wizard: %IP Compiler for PCI Express v14.0%
// GENERATION: XML
// ============================================================
// Megafunction Name(s):
// ============================================================

//Legal Notice: (C)2015 Altera Corporation. All rights reserved.  Your
//use of Altera Corporation's design tools, logic functions and other
//software and tools, and its AMPP partner logic functions, and any
//output files any of the foregoing (including device programming or
//simulation files), and any associated documentation or information are
//expressly subject to the terms and conditions of the Altera Program
//License Subscription Agreement or other applicable license agreement,
//including, without limitation, that your use is for the sole purpose
//of programming logic devices manufactured by Altera and sold by Altera
//or its authorized distributors.  Please refer to the applicable
//agreement for further details.

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

//$Revision: #1 
//Phy type: Stratix IV GX Hard IP 
//Number of Lanes: 8
//Ref Clk Freq: 100Mhz
//Number of VCs: 1
module siv_gen2x8 (
                    // inputs:
                     app_int_sts,
                     app_msi_num,
                     app_msi_req,
                     app_msi_tc,
                     busy_altgxb_reconfig,
                     cal_blk_clk,
                     cpl_err,
                     cpl_pending,
                     crst,
                     fixedclk_serdes,
                     gxb_powerdown,
                     hpg_ctrler,
                     lmi_addr,
                     lmi_din,
                     lmi_rden,
                     lmi_wren,
                     npor,
                     pclk_in,
                     pex_msi_num,
                     phystatus_ext,
                     pipe_mode,
                     pld_clk,
                     pll_powerdown,
                     pm_auxpwr,
                     pm_data,
                     pm_event,
                     pme_to_cr,
                     reconfig_clk,
                     reconfig_togxb,
                     refclk,
                     rx_in0,
                     rx_in1,
                     rx_in2,
                     rx_in3,
                     rx_in4,
                     rx_in5,
                     rx_in6,
                     rx_in7,
                     rx_st_mask0,
                     rx_st_ready0,
                     rxdata0_ext,
                     rxdata1_ext,
                     rxdata2_ext,
                     rxdata3_ext,
                     rxdata4_ext,
                     rxdata5_ext,
                     rxdata6_ext,
                     rxdata7_ext,
                     rxdatak0_ext,
                     rxdatak1_ext,
                     rxdatak2_ext,
                     rxdatak3_ext,
                     rxdatak4_ext,
                     rxdatak5_ext,
                     rxdatak6_ext,
                     rxdatak7_ext,
                     rxelecidle0_ext,
                     rxelecidle1_ext,
                     rxelecidle2_ext,
                     rxelecidle3_ext,
                     rxelecidle4_ext,
                     rxelecidle5_ext,
                     rxelecidle6_ext,
                     rxelecidle7_ext,
                     rxstatus0_ext,
                     rxstatus1_ext,
                     rxstatus2_ext,
                     rxstatus3_ext,
                     rxstatus4_ext,
                     rxstatus5_ext,
                     rxstatus6_ext,
                     rxstatus7_ext,
                     rxvalid0_ext,
                     rxvalid1_ext,
                     rxvalid2_ext,
                     rxvalid3_ext,
                     rxvalid4_ext,
                     rxvalid5_ext,
                     rxvalid6_ext,
                     rxvalid7_ext,
                     srst,
                     test_in,
                     tx_st_data0,
                     tx_st_empty0,
                     tx_st_eop0,
                     tx_st_err0,
                     tx_st_sop0,
                     tx_st_valid0,

                    // outputs:
                     app_int_ack,
                     app_msi_ack,
                     clk250_out,
                     clk500_out,
                     core_clk_out,
                     derr_cor_ext_rcv0,
                     derr_cor_ext_rpl,
                     derr_rpl,
                     dlup_exit,
                     hotrst_exit,
                     ko_cpl_spc_vc0,
                     l2_exit,
                     lane_act,
                     lmi_ack,
                     lmi_dout,
                     ltssm,
                     npd_alloc_1cred_vc0,
                     npd_cred_vio_vc0,
                     nph_alloc_1cred_vc0,
                     nph_cred_vio_vc0,
                     pme_to_sr,
                     powerdown_ext,
                     r2c_err0,
                     rate_ext,
                     rc_pll_locked,
                     rc_rx_digitalreset,
                     reconfig_fromgxb,
                     reset_status,
                     rx_fifo_empty0,
                     rx_fifo_full0,
                     rx_st_bardec0,
                     rx_st_be0,
                     rx_st_data0,
                     rx_st_empty0,
                     rx_st_eop0,
                     rx_st_err0,
                     rx_st_sop0,
                     rx_st_valid0,
                     rxpolarity0_ext,
                     rxpolarity1_ext,
                     rxpolarity2_ext,
                     rxpolarity3_ext,
                     rxpolarity4_ext,
                     rxpolarity5_ext,
                     rxpolarity6_ext,
                     rxpolarity7_ext,
                     suc_spd_neg,
                     tl_cfg_add,
                     tl_cfg_ctl,
                     tl_cfg_ctl_wr,
                     tl_cfg_sts,
                     tl_cfg_sts_wr,
                     tx_cred0,
                     tx_fifo_empty0,
                     tx_fifo_full0,
                     tx_fifo_rdptr0,
                     tx_fifo_wrptr0,
                     tx_out0,
                     tx_out1,
                     tx_out2,
                     tx_out3,
                     tx_out4,
                     tx_out5,
                     tx_out6,
                     tx_out7,
                     tx_st_ready0,
                     txcompl0_ext,
                     txcompl1_ext,
                     txcompl2_ext,
                     txcompl3_ext,
                     txcompl4_ext,
                     txcompl5_ext,
                     txcompl6_ext,
                     txcompl7_ext,
                     txdata0_ext,
                     txdata1_ext,
                     txdata2_ext,
                     txdata3_ext,
                     txdata4_ext,
                     txdata5_ext,
                     txdata6_ext,
                     txdata7_ext,
                     txdatak0_ext,
                     txdatak1_ext,
                     txdatak2_ext,
                     txdatak3_ext,
                     txdatak4_ext,
                     txdatak5_ext,
                     txdatak6_ext,
                     txdatak7_ext,
                     txdetectrx_ext,
                     txelecidle0_ext,
                     txelecidle1_ext,
                     txelecidle2_ext,
                     txelecidle3_ext,
                     txelecidle4_ext,
                     txelecidle5_ext,
                     txelecidle6_ext,
                     txelecidle7_ext
                  )
;

  output           app_int_ack;
  output           app_msi_ack;
  output           clk250_out;
  output           clk500_out;
  output           core_clk_out;
  output           derr_cor_ext_rcv0;
  output           derr_cor_ext_rpl;
  output           derr_rpl;
  output           dlup_exit;
  output           hotrst_exit;
  output  [ 19: 0] ko_cpl_spc_vc0;
  output           l2_exit;
  output  [  3: 0] lane_act;
  output           lmi_ack;
  output  [ 31: 0] lmi_dout;
  output  [  4: 0] ltssm;
  output           npd_alloc_1cred_vc0;
  output           npd_cred_vio_vc0;
  output           nph_alloc_1cred_vc0;
  output           nph_cred_vio_vc0;
  output           pme_to_sr;
  output  [  1: 0] powerdown_ext;
  output           r2c_err0;
  output           rate_ext;
  output           rc_pll_locked;
  output           rc_rx_digitalreset;
  output  [ 33: 0] reconfig_fromgxb;
  output           reset_status;
  output           rx_fifo_empty0;
  output           rx_fifo_full0;
  output  [  7: 0] rx_st_bardec0;
  output  [ 15: 0] rx_st_be0;
  output  [127: 0] rx_st_data0;
  output           rx_st_empty0;
  output           rx_st_eop0;
  output           rx_st_err0;
  output           rx_st_sop0;
  output           rx_st_valid0;
  output           rxpolarity0_ext;
  output           rxpolarity1_ext;
  output           rxpolarity2_ext;
  output           rxpolarity3_ext;
  output           rxpolarity4_ext;
  output           rxpolarity5_ext;
  output           rxpolarity6_ext;
  output           rxpolarity7_ext;
  output           suc_spd_neg;
  output  [  3: 0] tl_cfg_add;
  output  [ 31: 0] tl_cfg_ctl;
  output           tl_cfg_ctl_wr;
  output  [ 52: 0] tl_cfg_sts;
  output           tl_cfg_sts_wr;
  output  [ 35: 0] tx_cred0;
  output           tx_fifo_empty0;
  output           tx_fifo_full0;
  output  [  3: 0] tx_fifo_rdptr0;
  output  [  3: 0] tx_fifo_wrptr0;
  output           tx_out0;
  output           tx_out1;
  output           tx_out2;
  output           tx_out3;
  output           tx_out4;
  output           tx_out5;
  output           tx_out6;
  output           tx_out7;
  output           tx_st_ready0;
  output           txcompl0_ext;
  output           txcompl1_ext;
  output           txcompl2_ext;
  output           txcompl3_ext;
  output           txcompl4_ext;
  output           txcompl5_ext;
  output           txcompl6_ext;
  output           txcompl7_ext;
  output  [  7: 0] txdata0_ext;
  output  [  7: 0] txdata1_ext;
  output  [  7: 0] txdata2_ext;
  output  [  7: 0] txdata3_ext;
  output  [  7: 0] txdata4_ext;
  output  [  7: 0] txdata5_ext;
  output  [  7: 0] txdata6_ext;
  output  [  7: 0] txdata7_ext;
  output           txdatak0_ext;
  output           txdatak1_ext;
  output           txdatak2_ext;
  output           txdatak3_ext;
  output           txdatak4_ext;
  output           txdatak5_ext;
  output           txdatak6_ext;
  output           txdatak7_ext;
  output           txdetectrx_ext;
  output           txelecidle0_ext;
  output           txelecidle1_ext;
  output           txelecidle2_ext;
  output           txelecidle3_ext;
  output           txelecidle4_ext;
  output           txelecidle5_ext;
  output           txelecidle6_ext;
  output           txelecidle7_ext;
  input            app_int_sts;
  input   [  4: 0] app_msi_num;
  input            app_msi_req;
  input   [  2: 0] app_msi_tc;
  input            busy_altgxb_reconfig;
  input            cal_blk_clk;
  input   [  6: 0] cpl_err;
  input            cpl_pending;
  input            crst;
  input            fixedclk_serdes;
  input            gxb_powerdown;
  input   [  4: 0] hpg_ctrler;
  input   [ 11: 0] lmi_addr;
  input   [ 31: 0] lmi_din;
  input            lmi_rden;
  input            lmi_wren;
  input            npor;
  input            pclk_in;
  input   [  4: 0] pex_msi_num;
  input            phystatus_ext;
  input            pipe_mode;
  input            pld_clk;
  input            pll_powerdown;
  input            pm_auxpwr;
  input   [  9: 0] pm_data;
  input            pm_event;
  input            pme_to_cr;
  input            reconfig_clk;
  input   [  3: 0] reconfig_togxb;
  input            refclk;
  input            rx_in0;
  input            rx_in1;
  input            rx_in2;
  input            rx_in3;
  input            rx_in4;
  input            rx_in5;
  input            rx_in6;
  input            rx_in7;
  input            rx_st_mask0;
  input            rx_st_ready0;
  input   [  7: 0] rxdata0_ext;
  input   [  7: 0] rxdata1_ext;
  input   [  7: 0] rxdata2_ext;
  input   [  7: 0] rxdata3_ext;
  input   [  7: 0] rxdata4_ext;
  input   [  7: 0] rxdata5_ext;
  input   [  7: 0] rxdata6_ext;
  input   [  7: 0] rxdata7_ext;
  input            rxdatak0_ext;
  input            rxdatak1_ext;
  input            rxdatak2_ext;
  input            rxdatak3_ext;
  input            rxdatak4_ext;
  input            rxdatak5_ext;
  input            rxdatak6_ext;
  input            rxdatak7_ext;
  input            rxelecidle0_ext;
  input            rxelecidle1_ext;
  input            rxelecidle2_ext;
  input            rxelecidle3_ext;
  input            rxelecidle4_ext;
  input            rxelecidle5_ext;
  input            rxelecidle6_ext;
  input            rxelecidle7_ext;
  input   [  2: 0] rxstatus0_ext;
  input   [  2: 0] rxstatus1_ext;
  input   [  2: 0] rxstatus2_ext;
  input   [  2: 0] rxstatus3_ext;
  input   [  2: 0] rxstatus4_ext;
  input   [  2: 0] rxstatus5_ext;
  input   [  2: 0] rxstatus6_ext;
  input   [  2: 0] rxstatus7_ext;
  input            rxvalid0_ext;
  input            rxvalid1_ext;
  input            rxvalid2_ext;
  input            rxvalid3_ext;
  input            rxvalid4_ext;
  input            rxvalid5_ext;
  input            rxvalid6_ext;
  input            rxvalid7_ext;
  input            srst;
  input   [ 39: 0] test_in;
  input   [127: 0] tx_st_data0;
  input            tx_st_empty0;
  input            tx_st_eop0;
  input            tx_st_err0;
  input            tx_st_sop0;
  input            tx_st_valid0;

  wire             app_int_ack;
  wire             app_msi_ack;
  wire             clk250_out;
  wire             clk500_out;
  wire             core_clk_in;
  wire             core_clk_out;
  wire             derr_cor_ext_rcv0;
  wire             derr_cor_ext_rpl;
  wire             derr_rpl;
  wire             detect_mask_rxdrst;
  wire             dlup_exit;
  wire    [ 23: 0] eidle_infer_sel;
  wire             fifo_err;
  wire             gnd_AvlClk_i;
  wire    [ 11: 0] gnd_CraAddress_i;
  wire    [  3: 0] gnd_CraByteEnable_i;
  wire             gnd_CraChipSelect_i;
  wire             gnd_CraRead;
  wire             gnd_CraWrite;
  wire    [ 31: 0] gnd_CraWriteData_i;
  wire             gnd_Rstn_i;
  wire    [  5: 0] gnd_RxmIrqNum_i;
  wire             gnd_RxmIrq_i;
  wire             gnd_RxmReadDataValid_i;
  wire    [ 63: 0] gnd_RxmReadData_i;
  wire             gnd_RxmWaitRequest_i;
  wire    [ 16: 0] gnd_TxsAddress_i;
  wire    [  9: 0] gnd_TxsBurstCount_i;
  wire    [  7: 0] gnd_TxsByteEnable_i;
  wire             gnd_TxsChipSelect_i;
  wire             gnd_TxsRead_i;
  wire    [ 63: 0] gnd_TxsWriteData_i;
  wire             gnd_TxsWrite_i;
  wire             gxb_powerdown_int;
  wire    [  1: 0] hip_extraclkout;
  wire    [  7: 0] hip_tx_clkout;
  wire             hotrst_exit;
  wire    [ 19: 0] ko_cpl_spc_vc0;
  wire             l2_exit;
  wire    [  3: 0] lane_act;
  wire             lmi_ack;
  wire    [ 31: 0] lmi_dout;
  wire    [  4: 0] ltssm;
  wire             npd_alloc_1cred_vc0;
  wire             npd_cred_vio_vc0;
  wire             nph_alloc_1cred_vc0;
  wire             nph_cred_vio_vc0;
  wire             open_CraIrq_o;
  wire    [ 31: 0] open_CraReadData_o;
  wire             open_CraWaitRequest_o;
  wire    [ 31: 0] open_RxmAddress_o;
  wire    [  9: 0] open_RxmBurstCount_o;
  wire    [  7: 0] open_RxmByteEnable_o;
  wire             open_RxmRead_o;
  wire    [ 63: 0] open_RxmWriteData_o;
  wire             open_RxmWrite_o;
  wire             open_TxsReadDataValid_o;
  wire    [ 63: 0] open_TxsReadData_o;
  wire             open_TxsWaitRequest_o;
  wire             open_gxb_powerdown;
  wire             open_rc_rx_analogreset;
  wire             open_rc_tx_digitalreset;
  wire             open_rx_st_sop0_p1;
  wire             pclk_central;
  wire             pclk_central_serdes;
  wire             pclk_ch0;
  wire             pclk_ch0_serdes;
  wire    [  7: 0] phystatus;
  wire    [  7: 0] phystatus_pcs;
  wire             pipe_mode_int;
  wire             pll_fixed_clk;
  wire             pll_fixed_clk_serdes;
  wire             pll_locked;
  wire             pll_powerdown_int;
  wire             pme_to_sr;
  wire    [ 15: 0] powerdown;
  wire    [  1: 0] powerdown0_ext;
  wire    [  1: 0] powerdown0_int;
  wire    [  1: 0] powerdown1_ext;
  wire    [  1: 0] powerdown1_int;
  wire    [  1: 0] powerdown2_ext;
  wire    [  1: 0] powerdown2_int;
  wire    [  1: 0] powerdown3_ext;
  wire    [  1: 0] powerdown3_int;
  wire    [  1: 0] powerdown4_ext;
  wire    [  1: 0] powerdown4_int;
  wire    [  1: 0] powerdown5_ext;
  wire    [  1: 0] powerdown5_int;
  wire    [  1: 0] powerdown6_ext;
  wire    [  1: 0] powerdown6_int;
  wire    [  1: 0] powerdown7_ext;
  wire    [  1: 0] powerdown7_int;
  wire    [  1: 0] powerdown_ext;
  wire             r2c_err0;
  wire             rate_ext;
  wire             rate_int;
  wire    [  7: 0] rateswitch;
  wire    [  1: 0] rateswitchbaseclock;
  wire             rc_areset;
  wire             rc_inclk_eq_125mhz;
  wire             rc_pll_locked;
  wire             rc_rx_analogreset;
  wire             rc_rx_digitalreset;
  wire             rc_rx_pll_locked_one;
  wire             rc_tx_digitalreset;
  wire    [ 33: 0] reconfig_fromgxb;
  wire             reset_status;
  wire    [  7: 0] rx_cruclk;
  wire             rx_digitalreset_serdes;
  wire             rx_fifo_empty0;
  wire             rx_fifo_full0;
  wire    [  7: 0] rx_freqlocked;
  wire    [  7: 0] rx_freqlocked_byte;
  wire    [  7: 0] rx_in;
  wire    [  7: 0] rx_pll_locked;
  wire    [  7: 0] rx_pll_locked_byte;
  wire    [  7: 0] rx_signaldetect;
  wire    [  7: 0] rx_signaldetect_byte;
  wire    [  7: 0] rx_st_bardec0;
  wire    [ 15: 0] rx_st_be0;
  wire    [127: 0] rx_st_data0;
  wire             rx_st_empty0;
  wire             rx_st_eop0;
  wire             rx_st_err0;
  wire             rx_st_sop0;
  wire             rx_st_valid0;
  wire    [ 63: 0] rxdata;
  wire    [ 63: 0] rxdata_pcs;
  wire    [  7: 0] rxdatak;
  wire    [  7: 0] rxdatak_pcs;
  wire    [  7: 0] rxelecidle;
  wire    [  7: 0] rxelecidle_pcs;
  wire    [  7: 0] rxpolarity;
  wire             rxpolarity0_ext;
  wire             rxpolarity0_int;
  wire             rxpolarity1_ext;
  wire             rxpolarity1_int;
  wire             rxpolarity2_ext;
  wire             rxpolarity2_int;
  wire             rxpolarity3_ext;
  wire             rxpolarity3_int;
  wire             rxpolarity4_ext;
  wire             rxpolarity4_int;
  wire             rxpolarity5_ext;
  wire             rxpolarity5_int;
  wire             rxpolarity6_ext;
  wire             rxpolarity6_int;
  wire             rxpolarity7_ext;
  wire             rxpolarity7_int;
  wire    [ 23: 0] rxstatus;
  wire    [ 23: 0] rxstatus_pcs;
  wire    [  7: 0] rxvalid;
  wire    [  7: 0] rxvalid_pcs;
  wire             suc_spd_neg;
  wire    [ 63: 0] test_out_int;
  wire    [  3: 0] tl_cfg_add;
  wire    [ 31: 0] tl_cfg_ctl;
  wire             tl_cfg_ctl_wr;
  wire    [ 52: 0] tl_cfg_sts;
  wire             tl_cfg_sts_wr;
  wire    [ 35: 0] tx_cred0;
  wire    [  7: 0] tx_deemph;
  wire             tx_fifo_empty0;
  wire             tx_fifo_full0;
  wire    [  3: 0] tx_fifo_rdptr0;
  wire    [  3: 0] tx_fifo_wrptr0;
  wire    [ 23: 0] tx_margin;
  wire    [  7: 0] tx_out;
  wire             tx_out0;
  wire             tx_out1;
  wire             tx_out2;
  wire             tx_out3;
  wire             tx_out4;
  wire             tx_out5;
  wire             tx_out6;
  wire             tx_out7;
  wire             tx_st_ready0;
  wire    [  7: 0] txcompl;
  wire             txcompl0_ext;
  wire             txcompl0_int;
  wire             txcompl1_ext;
  wire             txcompl1_int;
  wire             txcompl2_ext;
  wire             txcompl2_int;
  wire             txcompl3_ext;
  wire             txcompl3_int;
  wire             txcompl4_ext;
  wire             txcompl4_int;
  wire             txcompl5_ext;
  wire             txcompl5_int;
  wire             txcompl6_ext;
  wire             txcompl6_int;
  wire             txcompl7_ext;
  wire             txcompl7_int;
  wire    [ 63: 0] txdata;
  wire    [  7: 0] txdata0_ext;
  wire    [  7: 0] txdata0_int;
  wire    [  7: 0] txdata1_ext;
  wire    [  7: 0] txdata1_int;
  wire    [  7: 0] txdata2_ext;
  wire    [  7: 0] txdata2_int;
  wire    [  7: 0] txdata3_ext;
  wire    [  7: 0] txdata3_int;
  wire    [  7: 0] txdata4_ext;
  wire    [  7: 0] txdata4_int;
  wire    [  7: 0] txdata5_ext;
  wire    [  7: 0] txdata5_int;
  wire    [  7: 0] txdata6_ext;
  wire    [  7: 0] txdata6_int;
  wire    [  7: 0] txdata7_ext;
  wire    [  7: 0] txdata7_int;
  wire    [  7: 0] txdatak;
  wire             txdatak0_ext;
  wire             txdatak0_int;
  wire             txdatak1_ext;
  wire             txdatak1_int;
  wire             txdatak2_ext;
  wire             txdatak2_int;
  wire             txdatak3_ext;
  wire             txdatak3_int;
  wire             txdatak4_ext;
  wire             txdatak4_int;
  wire             txdatak5_ext;
  wire             txdatak5_int;
  wire             txdatak6_ext;
  wire             txdatak6_int;
  wire             txdatak7_ext;
  wire             txdatak7_int;
  wire    [  7: 0] txdetectrx;
  wire             txdetectrx0_ext;
  wire             txdetectrx0_int;
  wire             txdetectrx1_ext;
  wire             txdetectrx1_int;
  wire             txdetectrx2_ext;
  wire             txdetectrx2_int;
  wire             txdetectrx3_ext;
  wire             txdetectrx3_int;
  wire             txdetectrx4_ext;
  wire             txdetectrx4_int;
  wire             txdetectrx5_ext;
  wire             txdetectrx5_int;
  wire             txdetectrx6_ext;
  wire             txdetectrx6_int;
  wire             txdetectrx7_ext;
  wire             txdetectrx7_int;
  wire             txdetectrx_ext;
  wire    [  7: 0] txelecidle;
  wire             txelecidle0_ext;
  wire             txelecidle0_int;
  wire             txelecidle1_ext;
  wire             txelecidle1_int;
  wire             txelecidle2_ext;
  wire             txelecidle2_int;
  wire             txelecidle3_ext;
  wire             txelecidle3_int;
  wire             txelecidle4_ext;
  wire             txelecidle4_int;
  wire             txelecidle5_ext;
  wire             txelecidle5_int;
  wire             txelecidle6_ext;
  wire             txelecidle6_int;
  wire             txelecidle7_ext;
  wire             txelecidle7_int;
  wire             use_c4gx_serdes;
  assign txdetectrx_ext = txdetectrx0_ext;
  assign powerdown_ext = powerdown0_ext;
  assign rxdata[7 : 0] = pipe_mode_int ? rxdata0_ext : rxdata_pcs[7 : 0];
  assign phystatus[0] = pipe_mode_int ? phystatus_ext : phystatus_pcs[0];
  assign rxelecidle[0] = pipe_mode_int ? rxelecidle0_ext : rxelecidle_pcs[0];
  assign rxvalid[0] = pipe_mode_int ? rxvalid0_ext : rxvalid_pcs[0];
  assign txdata[7 : 0] = txdata0_int;
  assign rxdatak[0] = pipe_mode_int ? rxdatak0_ext : rxdatak_pcs[0];
  assign rxstatus[2 : 0] = pipe_mode_int ? rxstatus0_ext : rxstatus_pcs[2 : 0];
  assign powerdown[1 : 0] = powerdown0_int;
  assign rxpolarity[0] = rxpolarity0_int;
  assign txcompl[0] = txcompl0_int;
  assign txdatak[0] = txdatak0_int;
  assign txdetectrx[0] = txdetectrx0_int;
  assign txelecidle[0] = txelecidle0_int;
  assign txdata0_ext = pipe_mode_int ? txdata0_int : 0;
  assign txdatak0_ext = pipe_mode_int ? txdatak0_int : 0;
  assign txdetectrx0_ext = pipe_mode_int ? txdetectrx0_int : 0;
  assign txelecidle0_ext = pipe_mode_int ? txelecidle0_int : 0;
  assign txcompl0_ext = pipe_mode_int ? txcompl0_int : 0;
  assign rxpolarity0_ext = pipe_mode_int ? rxpolarity0_int : 0;
  assign powerdown0_ext = pipe_mode_int ? powerdown0_int : 0;
  assign rxdata[15 : 8] = pipe_mode_int ? rxdata1_ext : rxdata_pcs[15 : 8];
  assign phystatus[1] = pipe_mode_int ? phystatus_ext : phystatus_pcs[1];
  assign rxelecidle[1] = pipe_mode_int ? rxelecidle1_ext : rxelecidle_pcs[1];
  assign rxvalid[1] = pipe_mode_int ? rxvalid1_ext : rxvalid_pcs[1];
  assign txdata[15 : 8] = txdata1_int;
  assign rxdatak[1] = pipe_mode_int ? rxdatak1_ext : rxdatak_pcs[1];
  assign rxstatus[5 : 3] = pipe_mode_int ? rxstatus1_ext : rxstatus_pcs[5 : 3];
  assign powerdown[3 : 2] = powerdown1_int;
  assign rxpolarity[1] = rxpolarity1_int;
  assign txcompl[1] = txcompl1_int;
  assign txdatak[1] = txdatak1_int;
  assign txdetectrx[1] = txdetectrx1_int;
  assign txelecidle[1] = txelecidle1_int;
  assign txdata1_ext = pipe_mode_int ? txdata1_int : 0;
  assign txdatak1_ext = pipe_mode_int ? txdatak1_int : 0;
  assign txdetectrx1_ext = pipe_mode_int ? txdetectrx1_int : 0;
  assign txelecidle1_ext = pipe_mode_int ? txelecidle1_int : 0;
  assign txcompl1_ext = pipe_mode_int ? txcompl1_int : 0;
  assign rxpolarity1_ext = pipe_mode_int ? rxpolarity1_int : 0;
  assign powerdown1_ext = pipe_mode_int ? powerdown1_int : 0;
  assign rxdata[23 : 16] = pipe_mode_int ? rxdata2_ext : rxdata_pcs[23 : 16];
  assign phystatus[2] = pipe_mode_int ? phystatus_ext : phystatus_pcs[2];
  assign rxelecidle[2] = pipe_mode_int ? rxelecidle2_ext : rxelecidle_pcs[2];
  assign rxvalid[2] = pipe_mode_int ? rxvalid2_ext : rxvalid_pcs[2];
  assign txdata[23 : 16] = txdata2_int;
  assign rxdatak[2] = pipe_mode_int ? rxdatak2_ext : rxdatak_pcs[2];
  assign rxstatus[8 : 6] = pipe_mode_int ? rxstatus2_ext : rxstatus_pcs[8 : 6];
  assign powerdown[5 : 4] = powerdown2_int;
  assign rxpolarity[2] = rxpolarity2_int;
  assign txcompl[2] = txcompl2_int;
  assign txdatak[2] = txdatak2_int;
  assign txdetectrx[2] = txdetectrx2_int;
  assign txelecidle[2] = txelecidle2_int;
  assign txdata2_ext = pipe_mode_int ? txdata2_int : 0;
  assign txdatak2_ext = pipe_mode_int ? txdatak2_int : 0;
  assign txdetectrx2_ext = pipe_mode_int ? txdetectrx2_int : 0;
  assign txelecidle2_ext = pipe_mode_int ? txelecidle2_int : 0;
  assign txcompl2_ext = pipe_mode_int ? txcompl2_int : 0;
  assign rxpolarity2_ext = pipe_mode_int ? rxpolarity2_int : 0;
  assign powerdown2_ext = pipe_mode_int ? powerdown2_int : 0;
  assign rxdata[31 : 24] = pipe_mode_int ? rxdata3_ext : rxdata_pcs[31 : 24];
  assign phystatus[3] = pipe_mode_int ? phystatus_ext : phystatus_pcs[3];
  assign rxelecidle[3] = pipe_mode_int ? rxelecidle3_ext : rxelecidle_pcs[3];
  assign rxvalid[3] = pipe_mode_int ? rxvalid3_ext : rxvalid_pcs[3];
  assign txdata[31 : 24] = txdata3_int;
  assign rxdatak[3] = pipe_mode_int ? rxdatak3_ext : rxdatak_pcs[3];
  assign rxstatus[11 : 9] = pipe_mode_int ? rxstatus3_ext : rxstatus_pcs[11 : 9];
  assign powerdown[7 : 6] = powerdown3_int;
  assign rxpolarity[3] = rxpolarity3_int;
  assign txcompl[3] = txcompl3_int;
  assign txdatak[3] = txdatak3_int;
  assign txdetectrx[3] = txdetectrx3_int;
  assign txelecidle[3] = txelecidle3_int;
  assign txdata3_ext = pipe_mode_int ? txdata3_int : 0;
  assign txdatak3_ext = pipe_mode_int ? txdatak3_int : 0;
  assign txdetectrx3_ext = pipe_mode_int ? txdetectrx3_int : 0;
  assign txelecidle3_ext = pipe_mode_int ? txelecidle3_int : 0;
  assign txcompl3_ext = pipe_mode_int ? txcompl3_int : 0;
  assign rxpolarity3_ext = pipe_mode_int ? rxpolarity3_int : 0;
  assign powerdown3_ext = pipe_mode_int ? powerdown3_int : 0;
  assign rxdata[39 : 32] = pipe_mode_int ? rxdata4_ext : rxdata_pcs[39 : 32];
  assign phystatus[4] = pipe_mode_int ? phystatus_ext : phystatus_pcs[4];
  assign rxelecidle[4] = pipe_mode_int ? rxelecidle4_ext : rxelecidle_pcs[4];
  assign rxvalid[4] = pipe_mode_int ? rxvalid4_ext : rxvalid_pcs[4];
  assign txdata[39 : 32] = txdata4_int;
  assign rxdatak[4] = pipe_mode_int ? rxdatak4_ext : rxdatak_pcs[4];
  assign rxstatus[14 : 12] = pipe_mode_int ? rxstatus4_ext : rxstatus_pcs[14 : 12];
  assign powerdown[9 : 8] = powerdown4_int;
  assign rxpolarity[4] = rxpolarity4_int;
  assign txcompl[4] = txcompl4_int;
  assign txdatak[4] = txdatak4_int;
  assign txdetectrx[4] = txdetectrx4_int;
  assign txelecidle[4] = txelecidle4_int;
  assign txdata4_ext = pipe_mode_int ? txdata4_int : 0;
  assign txdatak4_ext = pipe_mode_int ? txdatak4_int : 0;
  assign txdetectrx4_ext = pipe_mode_int ? txdetectrx4_int : 0;
  assign txelecidle4_ext = pipe_mode_int ? txelecidle4_int : 0;
  assign txcompl4_ext = pipe_mode_int ? txcompl4_int : 0;
  assign rxpolarity4_ext = pipe_mode_int ? rxpolarity4_int : 0;
  assign powerdown4_ext = pipe_mode_int ? powerdown4_int : 0;
  assign rxdata[47 : 40] = pipe_mode_int ? rxdata5_ext : rxdata_pcs[47 : 40];
  assign phystatus[5] = pipe_mode_int ? phystatus_ext : phystatus_pcs[5];
  assign rxelecidle[5] = pipe_mode_int ? rxelecidle5_ext : rxelecidle_pcs[5];
  assign rxvalid[5] = pipe_mode_int ? rxvalid5_ext : rxvalid_pcs[5];
  assign txdata[47 : 40] = txdata5_int;
  assign rxdatak[5] = pipe_mode_int ? rxdatak5_ext : rxdatak_pcs[5];
  assign rxstatus[17 : 15] = pipe_mode_int ? rxstatus5_ext : rxstatus_pcs[17 : 15];
  assign powerdown[11 : 10] = powerdown5_int;
  assign rxpolarity[5] = rxpolarity5_int;
  assign txcompl[5] = txcompl5_int;
  assign txdatak[5] = txdatak5_int;
  assign txdetectrx[5] = txdetectrx5_int;
  assign txelecidle[5] = txelecidle5_int;
  assign txdata5_ext = pipe_mode_int ? txdata5_int : 0;
  assign txdatak5_ext = pipe_mode_int ? txdatak5_int : 0;
  assign txdetectrx5_ext = pipe_mode_int ? txdetectrx5_int : 0;
  assign txelecidle5_ext = pipe_mode_int ? txelecidle5_int : 0;
  assign txcompl5_ext = pipe_mode_int ? txcompl5_int : 0;
  assign rxpolarity5_ext = pipe_mode_int ? rxpolarity5_int : 0;
  assign powerdown5_ext = pipe_mode_int ? powerdown5_int : 0;
  assign rxdata[55 : 48] = pipe_mode_int ? rxdata6_ext : rxdata_pcs[55 : 48];
  assign phystatus[6] = pipe_mode_int ? phystatus_ext : phystatus_pcs[6];
  assign rxelecidle[6] = pipe_mode_int ? rxelecidle6_ext : rxelecidle_pcs[6];
  assign rxvalid[6] = pipe_mode_int ? rxvalid6_ext : rxvalid_pcs[6];
  assign txdata[55 : 48] = txdata6_int;
  assign rxdatak[6] = pipe_mode_int ? rxdatak6_ext : rxdatak_pcs[6];
  assign rxstatus[20 : 18] = pipe_mode_int ? rxstatus6_ext : rxstatus_pcs[20 : 18];
  assign powerdown[13 : 12] = powerdown6_int;
  assign rxpolarity[6] = rxpolarity6_int;
  assign txcompl[6] = txcompl6_int;
  assign txdatak[6] = txdatak6_int;
  assign txdetectrx[6] = txdetectrx6_int;
  assign txelecidle[6] = txelecidle6_int;
  assign txdata6_ext = pipe_mode_int ? txdata6_int : 0;
  assign txdatak6_ext = pipe_mode_int ? txdatak6_int : 0;
  assign txdetectrx6_ext = pipe_mode_int ? txdetectrx6_int : 0;
  assign txelecidle6_ext = pipe_mode_int ? txelecidle6_int : 0;
  assign txcompl6_ext = pipe_mode_int ? txcompl6_int : 0;
  assign rxpolarity6_ext = pipe_mode_int ? rxpolarity6_int : 0;
  assign powerdown6_ext = pipe_mode_int ? powerdown6_int : 0;
  assign rxdata[63 : 56] = pipe_mode_int ? rxdata7_ext : rxdata_pcs[63 : 56];
  assign phystatus[7] = pipe_mode_int ? phystatus_ext : phystatus_pcs[7];
  assign rxelecidle[7] = pipe_mode_int ? rxelecidle7_ext : rxelecidle_pcs[7];
  assign rxvalid[7] = pipe_mode_int ? rxvalid7_ext : rxvalid_pcs[7];
  assign txdata[63 : 56] = txdata7_int;
  assign rxdatak[7] = pipe_mode_int ? rxdatak7_ext : rxdatak_pcs[7];
  assign rxstatus[23 : 21] = pipe_mode_int ? rxstatus7_ext : rxstatus_pcs[23 : 21];
  assign powerdown[15 : 14] = powerdown7_int;
  assign rxpolarity[7] = rxpolarity7_int;
  assign txcompl[7] = txcompl7_int;
  assign txdatak[7] = txdatak7_int;
  assign txdetectrx[7] = txdetectrx7_int;
  assign txelecidle[7] = txelecidle7_int;
  assign txdata7_ext = pipe_mode_int ? txdata7_int : 0;
  assign txdatak7_ext = pipe_mode_int ? txdatak7_int : 0;
  assign txdetectrx7_ext = pipe_mode_int ? txdetectrx7_int : 0;
  assign txelecidle7_ext = pipe_mode_int ? txelecidle7_int : 0;
  assign txcompl7_ext = pipe_mode_int ? txcompl7_int : 0;
  assign rxpolarity7_ext = pipe_mode_int ? rxpolarity7_int : 0;
  assign powerdown7_ext = pipe_mode_int ? powerdown7_int : 0;
  assign ko_cpl_spc_vc0 = 20'h1c070;
  assign rx_in[0] = rx_in0;
  assign tx_out0 = tx_out[0];
  assign rx_in[1] = rx_in1;
  assign tx_out1 = tx_out[1];
  assign rx_in[2] = rx_in2;
  assign tx_out2 = tx_out[2];
  assign rx_in[3] = rx_in3;
  assign tx_out3 = tx_out[3];
  assign rx_in[4] = rx_in4;
  assign tx_out4 = tx_out[4];
  assign rx_in[5] = rx_in5;
  assign tx_out5 = tx_out[5];
  assign rx_in[6] = rx_in6;
  assign tx_out6 = tx_out[6];
  assign rx_in[7] = rx_in7;
  assign tx_out7 = tx_out[7];
  assign rc_inclk_eq_125mhz = 0;
  assign pclk_central_serdes = hip_tx_clkout[0];
  assign pclk_ch0_serdes = pclk_central_serdes;
  assign pll_fixed_clk_serdes = rateswitchbaseclock[0];
  assign rc_pll_locked = (pipe_mode_int == 1'b1) ? 1'b1 : &pll_locked;
  assign gxb_powerdown_int = (pipe_mode_int == 1'b1) ? 1'b1 : gxb_powerdown;
  assign pll_powerdown_int = (pipe_mode_int == 1'b1) ? 1'b1 : pll_powerdown;
  assign rx_cruclk = {8{refclk}};
  assign rc_areset = pipe_mode_int | ~npor | busy_altgxb_reconfig;
  assign pclk_central = (pipe_mode_int == 1'b1) ? pclk_in : pclk_central_serdes;
  assign pclk_ch0 = (pipe_mode_int == 1'b1) ? pclk_in : pclk_ch0_serdes;
  assign rateswitch = {8{rate_int}};
  assign rate_ext = pipe_mode_int ? rate_int : 0;
  assign pll_fixed_clk = (pipe_mode_int == 1'b1) ? clk500_out : pll_fixed_clk_serdes;
  assign rc_rx_pll_locked_one = &(rx_pll_locked | rx_freqlocked);
  assign use_c4gx_serdes = 1'b0;
  assign fifo_err = 1'b0;
  assign rx_freqlocked_byte[7 : 0] = rx_freqlocked[7 : 0];
  assign rx_pll_locked_byte[7 : 0] = rx_pll_locked[7 : 0];
  assign rx_signaldetect_byte[7 : 0] = rx_signaldetect[7 : 0];
  assign detect_mask_rxdrst = 1'b0;
  assign core_clk_in = 1'b0;
  assign gnd_AvlClk_i = 1'b0;
  assign gnd_Rstn_i = 1'b0;
  assign gnd_TxsChipSelect_i = 1'b0;
  assign gnd_TxsRead_i = 1'b0;
  assign gnd_TxsWrite_i = 1'b0;
  assign gnd_TxsWriteData_i = 1'b0;
  assign gnd_TxsBurstCount_i = 1'b0;
  assign gnd_TxsAddress_i = 1'b0;
  assign gnd_TxsByteEnable_i = 1'b0;
  assign gnd_RxmWaitRequest_i = 1'b0;
  assign gnd_RxmReadData_i = 1'b0;
  assign gnd_RxmReadDataValid_i = 1'b0;
  assign gnd_RxmIrq_i = 1'b0;
  assign gnd_RxmIrqNum_i = 1'b0;
  assign gnd_CraChipSelect_i = 1'b0;
  assign gnd_CraRead = 1'b0;
  assign gnd_CraWrite = 1'b0;
  assign gnd_CraWriteData_i = 1'b0;
  assign gnd_CraAddress_i = 1'b0;
  assign gnd_CraByteEnable_i = 1'b0;
  siv_gen2x8_serdes serdes
    (
      .cal_blk_clk (cal_blk_clk),
      .fixedclk (fixedclk_serdes),
      .gxb_powerdown (gxb_powerdown_int),
      .hip_tx_clkout (hip_tx_clkout),
      .pipe8b10binvpolarity (rxpolarity),
      .pipedatavalid (rxvalid_pcs),
      .pipeelecidle (rxelecidle_pcs),
      .pipephydonestatus (phystatus_pcs),
      .pipestatus (rxstatus_pcs),
      .pll_inclk (refclk),
      .pll_locked (pll_locked),
      .pll_powerdown (pll_powerdown_int),
      .powerdn (powerdown),
      .rateswitch (rateswitch[0]),
      .rateswitchbaseclock (rateswitchbaseclock),
      .reconfig_clk (reconfig_clk),
      .reconfig_fromgxb (reconfig_fromgxb),
      .reconfig_togxb (reconfig_togxb),
      .rx_analogreset (rc_rx_analogreset),
      .rx_cruclk (rx_cruclk),
      .rx_ctrldetect (rxdatak_pcs),
      .rx_datain (rx_in),
      .rx_dataout (rxdata_pcs),
      .rx_digitalreset (rx_digitalreset_serdes),
      .rx_elecidleinfersel (eidle_infer_sel[23 : 0]),
      .rx_freqlocked (rx_freqlocked),
      .rx_pll_locked (rx_pll_locked),
      .rx_signaldetect (rx_signaldetect),
      .tx_ctrlenable (txdatak),
      .tx_datain (txdata),
      .tx_dataout (tx_out),
      .tx_detectrxloop (txdetectrx),
      .tx_digitalreset (rc_tx_digitalreset),
      .tx_forcedispcompliance (txcompl),
      .tx_forceelecidle (txelecidle),
      .tx_pipedeemph (tx_deemph[7 : 0]),
      .tx_pipemargin (tx_margin[23 : 0])
    );


  altpcie_rs_serdes rs_serdes
    (
      .busy_altgxb_reconfig (busy_altgxb_reconfig),
      .detect_mask_rxdrst (detect_mask_rxdrst),
      .fifo_err (fifo_err),
      .ltssm (ltssm),
      .npor (npor),
      .pld_clk (pld_clk),
      .pll_locked (rc_pll_locked),
      .rc_inclk_eq_125mhz (rc_inclk_eq_125mhz),
      .rx_freqlocked (rx_freqlocked_byte),
      .rx_pll_locked (rx_pll_locked_byte),
      .rx_signaldetect (rx_signaldetect_byte),
      .rxanalogreset (rc_rx_analogreset),
      .rxdigitalreset (rx_digitalreset_serdes),
      .test_in (test_in),
      .txdigitalreset (rc_tx_digitalreset),
      .use_c4gx_serdes (use_c4gx_serdes)
    );


  siv_gen2x8_core wrapper
    (
      .AvlClk_i (gnd_AvlClk_i),
      .CraAddress_i (gnd_CraAddress_i),
      .CraByteEnable_i (gnd_CraByteEnable_i),
      .CraChipSelect_i (gnd_CraChipSelect_i),
      .CraIrq_o (open_CraIrq_o),
      .CraRead (gnd_CraRead),
      .CraReadData_o (open_CraReadData_o),
      .CraWaitRequest_o (open_CraWaitRequest_o),
      .CraWrite (gnd_CraWrite),
      .CraWriteData_i (gnd_CraWriteData_i),
      .Rstn_i (gnd_Rstn_i),
      .RxmAddress_o (open_RxmAddress_o),
      .RxmBurstCount_o (open_RxmBurstCount_o),
      .RxmByteEnable_o (open_RxmByteEnable_o),
      .RxmIrqNum_i (gnd_RxmIrqNum_i),
      .RxmIrq_i (gnd_RxmIrq_i),
      .RxmReadDataValid_i (gnd_RxmReadDataValid_i),
      .RxmReadData_i (gnd_RxmReadData_i),
      .RxmRead_o (open_RxmRead_o),
      .RxmWaitRequest_i (gnd_RxmWaitRequest_i),
      .RxmWriteData_o (open_RxmWriteData_o),
      .RxmWrite_o (open_RxmWrite_o),
      .TxsAddress_i (gnd_TxsAddress_i),
      .TxsBurstCount_i (gnd_TxsBurstCount_i),
      .TxsByteEnable_i (gnd_TxsByteEnable_i),
      .TxsChipSelect_i (gnd_TxsChipSelect_i),
      .TxsReadDataValid_o (open_TxsReadDataValid_o),
      .TxsReadData_o (open_TxsReadData_o),
      .TxsRead_i (gnd_TxsRead_i),
      .TxsWaitRequest_o (open_TxsWaitRequest_o),
      .TxsWriteData_i (gnd_TxsWriteData_i),
      .TxsWrite_i (gnd_TxsWrite_i),
      .aer_msi_num (5'b00000),
      .app_int_ack (app_int_ack),
      .app_int_sts (app_int_sts),
      .app_msi_ack (app_msi_ack),
      .app_msi_num (app_msi_num),
      .app_msi_req (app_msi_req),
      .app_msi_tc (app_msi_tc),
      .core_clk_in (core_clk_in),
      .core_clk_out (core_clk_out),
      .cpl_err (cpl_err),
      .cpl_pending (cpl_pending),
      .crst (crst),
      .derr_cor_ext_rcv0 (derr_cor_ext_rcv0),
      .derr_cor_ext_rpl (derr_cor_ext_rpl),
      .derr_rpl (derr_rpl),
      .dl_ltssm (ltssm),
      .dlup_exit (dlup_exit),
      .eidle_infer_sel (eidle_infer_sel),
      .hip_extraclkout (hip_extraclkout),
      .hotrst_exit (hotrst_exit),
      .hpg_ctrler (hpg_ctrler),
      .l2_exit (l2_exit),
      .lane_act (lane_act),
      .lmi_ack (lmi_ack),
      .lmi_addr (lmi_addr),
      .lmi_din (lmi_din),
      .lmi_dout (lmi_dout),
      .lmi_rden (lmi_rden),
      .lmi_wren (lmi_wren),
      .npd_alloc_1cred_vc0 (npd_alloc_1cred_vc0),
      .npd_cred_vio_vc0 (npd_cred_vio_vc0),
      .nph_alloc_1cred_vc0 (nph_alloc_1cred_vc0),
      .nph_cred_vio_vc0 (nph_cred_vio_vc0),
      .npor (npor),
      .pclk_central (pclk_central),
      .pclk_ch0 (pclk_ch0),
      .pex_msi_num (pex_msi_num),
      .phystatus0_ext (phystatus[0]),
      .phystatus1_ext (phystatus[1]),
      .phystatus2_ext (phystatus[2]),
      .phystatus3_ext (phystatus[3]),
      .phystatus4_ext (phystatus[4]),
      .phystatus5_ext (phystatus[5]),
      .phystatus6_ext (phystatus[6]),
      .phystatus7_ext (phystatus[7]),
      .pld_clk (pld_clk),
      .pll_fixed_clk (pll_fixed_clk),
      .pm_auxpwr (pm_auxpwr),
      .pm_data (pm_data),
      .pm_event (pm_event),
      .pme_to_cr (pme_to_cr),
      .pme_to_sr (pme_to_sr),
      .powerdown0_ext (powerdown0_int),
      .powerdown1_ext (powerdown1_int),
      .powerdown2_ext (powerdown2_int),
      .powerdown3_ext (powerdown3_int),
      .powerdown4_ext (powerdown4_int),
      .powerdown5_ext (powerdown5_int),
      .powerdown6_ext (powerdown6_int),
      .powerdown7_ext (powerdown7_int),
      .r2c_err0 (r2c_err0),
      .rate_ext (rate_int),
      .rc_areset (rc_areset),
      .rc_gxb_powerdown (open_gxb_powerdown),
      .rc_inclk_eq_125mhz (rc_inclk_eq_125mhz),
      .rc_pll_locked (rc_pll_locked),
      .rc_rx_analogreset (open_rc_rx_analogreset),
      .rc_rx_digitalreset (rc_rx_digitalreset),
      .rc_rx_pll_locked_one (rc_rx_pll_locked_one),
      .rc_tx_digitalreset (open_rc_tx_digitalreset),
      .reset_status (reset_status),
      .rx_fifo_empty0 (rx_fifo_empty0),
      .rx_fifo_full0 (rx_fifo_full0),
      .rx_st_bardec0 (rx_st_bardec0),
      .rx_st_be0 (rx_st_be0[7 : 0]),
      .rx_st_be0_p1 (rx_st_be0[15 : 8]),
      .rx_st_data0 (rx_st_data0[63 : 0]),
      .rx_st_data0_p1 (rx_st_data0[127 : 64]),
      .rx_st_eop0 (rx_st_empty0),
      .rx_st_eop0_p1 (rx_st_eop0),
      .rx_st_err0 (rx_st_err0),
      .rx_st_mask0 (rx_st_mask0),
      .rx_st_ready0 (rx_st_ready0),
      .rx_st_sop0 (rx_st_sop0),
      .rx_st_sop0_p1 (open_rx_st_sop0_p1),
      .rx_st_valid0 (rx_st_valid0),
      .rxdata0_ext (rxdata[7 : 0]),
      .rxdata1_ext (rxdata[15 : 8]),
      .rxdata2_ext (rxdata[23 : 16]),
      .rxdata3_ext (rxdata[31 : 24]),
      .rxdata4_ext (rxdata[39 : 32]),
      .rxdata5_ext (rxdata[47 : 40]),
      .rxdata6_ext (rxdata[55 : 48]),
      .rxdata7_ext (rxdata[63 : 56]),
      .rxdatak0_ext (rxdatak[0]),
      .rxdatak1_ext (rxdatak[1]),
      .rxdatak2_ext (rxdatak[2]),
      .rxdatak3_ext (rxdatak[3]),
      .rxdatak4_ext (rxdatak[4]),
      .rxdatak5_ext (rxdatak[5]),
      .rxdatak6_ext (rxdatak[6]),
      .rxdatak7_ext (rxdatak[7]),
      .rxelecidle0_ext (rxelecidle[0]),
      .rxelecidle1_ext (rxelecidle[1]),
      .rxelecidle2_ext (rxelecidle[2]),
      .rxelecidle3_ext (rxelecidle[3]),
      .rxelecidle4_ext (rxelecidle[4]),
      .rxelecidle5_ext (rxelecidle[5]),
      .rxelecidle6_ext (rxelecidle[6]),
      .rxelecidle7_ext (rxelecidle[7]),
      .rxpolarity0_ext (rxpolarity0_int),
      .rxpolarity1_ext (rxpolarity1_int),
      .rxpolarity2_ext (rxpolarity2_int),
      .rxpolarity3_ext (rxpolarity3_int),
      .rxpolarity4_ext (rxpolarity4_int),
      .rxpolarity5_ext (rxpolarity5_int),
      .rxpolarity6_ext (rxpolarity6_int),
      .rxpolarity7_ext (rxpolarity7_int),
      .rxstatus0_ext (rxstatus[2 : 0]),
      .rxstatus1_ext (rxstatus[5 : 3]),
      .rxstatus2_ext (rxstatus[8 : 6]),
      .rxstatus3_ext (rxstatus[11 : 9]),
      .rxstatus4_ext (rxstatus[14 : 12]),
      .rxstatus5_ext (rxstatus[17 : 15]),
      .rxstatus6_ext (rxstatus[20 : 18]),
      .rxstatus7_ext (rxstatus[23 : 21]),
      .rxvalid0_ext (rxvalid[0]),
      .rxvalid1_ext (rxvalid[1]),
      .rxvalid2_ext (rxvalid[2]),
      .rxvalid3_ext (rxvalid[3]),
      .rxvalid4_ext (rxvalid[4]),
      .rxvalid5_ext (rxvalid[5]),
      .rxvalid6_ext (rxvalid[6]),
      .rxvalid7_ext (rxvalid[7]),
      .srst (srst),
      .suc_spd_neg (suc_spd_neg),
      .test_in (test_in),
      .test_out (test_out_int),
      .tl_cfg_add (tl_cfg_add),
      .tl_cfg_ctl (tl_cfg_ctl),
      .tl_cfg_ctl_wr (tl_cfg_ctl_wr),
      .tl_cfg_sts (tl_cfg_sts),
      .tl_cfg_sts_wr (tl_cfg_sts_wr),
      .tx_cred0 (tx_cred0),
      .tx_deemph (tx_deemph),
      .tx_fifo_empty0 (tx_fifo_empty0),
      .tx_fifo_full0 (tx_fifo_full0),
      .tx_fifo_rdptr0 (tx_fifo_rdptr0),
      .tx_fifo_wrptr0 (tx_fifo_wrptr0),
      .tx_margin (tx_margin),
      .tx_st_data0 (tx_st_data0[63 : 0]),
      .tx_st_data0_p1 (tx_st_data0[127 : 64]),
      .tx_st_eop0 (tx_st_empty0),
      .tx_st_eop0_p1 (tx_st_eop0),
      .tx_st_err0 (tx_st_err0),
      .tx_st_ready0 (tx_st_ready0),
      .tx_st_sop0 (tx_st_sop0),
      .tx_st_sop0_p1 (1'b0),
      .tx_st_valid0 (tx_st_valid0),
      .txcompl0_ext (txcompl0_int),
      .txcompl1_ext (txcompl1_int),
      .txcompl2_ext (txcompl2_int),
      .txcompl3_ext (txcompl3_int),
      .txcompl4_ext (txcompl4_int),
      .txcompl5_ext (txcompl5_int),
      .txcompl6_ext (txcompl6_int),
      .txcompl7_ext (txcompl7_int),
      .txdata0_ext (txdata0_int),
      .txdata1_ext (txdata1_int),
      .txdata2_ext (txdata2_int),
      .txdata3_ext (txdata3_int),
      .txdata4_ext (txdata4_int),
      .txdata5_ext (txdata5_int),
      .txdata6_ext (txdata6_int),
      .txdata7_ext (txdata7_int),
      .txdatak0_ext (txdatak0_int),
      .txdatak1_ext (txdatak1_int),
      .txdatak2_ext (txdatak2_int),
      .txdatak3_ext (txdatak3_int),
      .txdatak4_ext (txdatak4_int),
      .txdatak5_ext (txdatak5_int),
      .txdatak6_ext (txdatak6_int),
      .txdatak7_ext (txdatak7_int),
      .txdetectrx0_ext (txdetectrx0_int),
      .txdetectrx1_ext (txdetectrx1_int),
      .txdetectrx2_ext (txdetectrx2_int),
      .txdetectrx3_ext (txdetectrx3_int),
      .txdetectrx4_ext (txdetectrx4_int),
      .txdetectrx5_ext (txdetectrx5_int),
      .txdetectrx6_ext (txdetectrx6_int),
      .txdetectrx7_ext (txdetectrx7_int),
      .txelecidle0_ext (txelecidle0_int),
      .txelecidle1_ext (txelecidle1_int),
      .txelecidle2_ext (txelecidle2_int),
      .txelecidle3_ext (txelecidle3_int),
      .txelecidle4_ext (txelecidle4_int),
      .txelecidle5_ext (txelecidle5_int),
      .txelecidle6_ext (txelecidle6_int),
      .txelecidle7_ext (txelecidle7_int)
    );



//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
  assign pipe_mode_int = pipe_mode;
  altpcie_pll_100_250 refclk_to_250mhz
    (
      .areset (1'b0),
      .c0 (clk250_out),
      .inclk0 (refclk)
    );


  altpcie_pll_125_250 pll_250mhz_to_500mhz
    (
      .areset (1'b0),
      .c0 (clk500_out),
      .inclk0 (clk250_out)
    );



//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on
//synthesis read_comments_as_HDL on
//  assign pipe_mode_int = 0;
//synthesis read_comments_as_HDL off

endmodule


// =========================================================
// IP Compiler for PCI Express Wizard Data
// ===============================
// DO NOT EDIT FOLLOWING DATA
// @Altera, IP Toolbench@
// Warning: If you modify this section, IP Compiler for PCI Express Wizard may not be able to reproduce your chosen configuration.
// 
// Retrieval info: <?xml version="1.0"?>
// Retrieval info: <MEGACORE title="IP Compiler for PCI Express"  version="14.0"  build="200"  iptb_version="1.3.0 Build 200"  format_version="120" >
// Retrieval info:  <NETLIST_SECTION class="altera.ipbu.flowbase.netlist.model.MVCModel"  active_core="altpcie_hip_pipen1b" >
// Retrieval info:   <STATIC_SECTION>
// Retrieval info:    <PRIVATES>
// Retrieval info:     <NAMESPACE name = "parameterization">
// Retrieval info:      <PRIVATE name = "p_pcie_phy" value="Stratix IV GX"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_port_type" value="Native Endpoint"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_tag_supported" value="64"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_msi_message_requested" value="4"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_low_priority_virtual_channels" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_retry_fifo_depth" value="64"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nfts_common_clock" value="255"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nfts_separate_clock" value="255"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_exp_rom_bar_used" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_link_common_clock" value="1"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_advanced_error_reporting" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_ecrc_check" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_ecrc_generation" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_power_indicator" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_attention_indicator" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_attention_button" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_msi_message_64bits_address_capable" value="1"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_auto_configure_retry_buffer" value="1"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_implement_data_register" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_device_init_required" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_enable_L1_aspm" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_rate_match_fifo" value="1"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_enable_fast_recovery" value="1"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "SOPCSystemName" value="N/A"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "actualBAR0AvalonAddress" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "actualBAR0Size" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "actualBAR1AvalonAddress" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "actualBAR1Size" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "actualBAR2AvalonAddress" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "actualBAR2Size" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "actualBAR3AvalonAddress" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "actualBAR3Size" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "actualBAR4AvalonAddress" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "actualBAR4Size" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "actualBAR5AvalonAddress" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "actualBAR5Size" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "allowedDeviceFamilies" value="[Arria II GX, Arria II GZ, Arria V, Arria V GZ, Cyclone IV E, Cyclone IV GX, Cyclone V, MAX II, MAX V, Stratix IV, Stratix V]"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "altgx_generated" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "clockSource" value="N/A"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "contextState" value="NativeContext"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "deviceFamily" value="Stratix IV"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "ordering_code" value="IP-PCIE/4"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hardwired_address_map" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_00" value="0x0000000000000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_00_type" value="Memory32Bit"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_01" value="0x0000000000000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_01_type" value="Memory32Bit"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_02" value="0x0000000000000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_02_type" value="Memory32Bit"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_03" value="0x0000000000000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_03_type" value="Memory32Bit"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_04" value="0x0000000000000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_04_type" value="Memory32Bit"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_05" value="0x0000000000000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_05_type" value="Memory32Bit"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_06" value="0x0000000000000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_06_type" value="Memory32Bit"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_07" value="0x0000000000000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_07_type" value="Memory32Bit"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_08" value="0x0000000000000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_08_type" value="Memory32Bit"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_09" value="0x0000000000000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_09_type" value="Memory32Bit"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_10" value="0x0000000000000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_10_type" value="Memory32Bit"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_11" value="0x0000000000000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_11_type" value="Memory32Bit"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_12" value="0x0000000000000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_12_type" value="Memory32Bit"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_13" value="0x0000000000000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_13_type" value="Memory32Bit"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_14" value="0x0000000000000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_14_type" value="Memory32Bit"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_15" value="0x0000000000000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_hw_pci_address_15_type" value="Memory32Bit"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_pane_count" value="1"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_avalon_pane_size" value="20"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_enable_pcie_hip_dprio" value="Disable"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_64bit_bar" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_64bit_bus" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_66mhz" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_allow_param_readback" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_altera_arbiter" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_arbited_devices" value="2"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_arbiter" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_0_auto_avalon_address" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_0_auto_sized" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_0_avalon_address" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_0_hardwired" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_0_pci_address" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_0_prefetchable" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_1_auto_avalon_address" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_1_auto_sized" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_1_avalon_address" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_1_hardwired" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_1_pci_address" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_1_prefetchable" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_2_auto_avalon_address" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_2_auto_sized" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_2_avalon_address" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_2_hardwired" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_2_pci_address" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_2_prefetchable" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_3_auto_avalon_address" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_3_auto_sized" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_3_avalon_address" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_3_hardwired" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_3_pci_address" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_3_prefetchable" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_4_auto_avalon_address" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_4_auto_sized" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_4_avalon_address" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_4_hardwired" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_4_pci_address" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_4_prefetchable" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_5_auto_avalon_address" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_5_auto_sized" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_5_avalon_address" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_5_hardwired" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_5_pci_address" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bar_5_prefetchable" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_bus_access_address_width" value="18"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_global_reset" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_host_bridge" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_impl_cra_av_slave_port" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_master" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_master_bursts" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_master_concurrent_reads" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_master_data_width" value="64"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_maximum_burst_size" value="128"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_maximum_burst_size_a2p" value="128"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_maximum_pending_read_transactions_a2p" value="8"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_non_pref_av_master_port" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_not_target_only_port" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_pref_av_master_port" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_reqn_gntn_pins" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_single_clock" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_target_bursts" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_target_concurrent_reads" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pci_user_specified_bars" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_L1_exit_latency_common_clock" value="&gt;64 us"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_L1_exit_latency_separate_clock" value="&gt;64 us"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_advanced_error_int_num" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_alt2gxb" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_altgx_keyParameters_used" value="{p_pcie_enable_hip=1, p_pcie_number_of_lanes=x8, p_pcie_phy=Stratix IV GX, p_pcie_rate=Gen2 (5.0 Gbps), p_pcie_txrx_clock=100 MHz}"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_app_signal_interface" value="AvalonST128"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_avalon_mm_lite" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_size_bar_0" value="16 KBytes - 14 bits"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_size_bar_1" value="N/A"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_size_bar_2" value="1 MByte - 20 bits"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_size_bar_3" value="N/A"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_size_bar_4" value="N/A"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_size_bar_5" value="N/A"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_type_bar_0" value="64-bit Prefetchable Memory"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_type_bar_1" value="N/A"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_type_bar_2" value="64-bit Prefetchable Memory"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_type_bar_3" value="N/A"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_type_bar_4" value="Disable this and all higher BARs"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_type_bar_5" value="Disable this and all higher BARs"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_used_bar_0" value="1"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_used_bar_1" value="1"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_used_bar_2" value="1"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_used_bar_3" value="1"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_used_bar_4" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_bar_used_bar_5" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_channel_number" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_chk_io" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_class_code" value="0xFF0000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_data_credit_vc0" value="448"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_data_credit_vc1" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_data_credit_vc2" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_data_credit_vc3" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_data_used_space_vc0" value="7168"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_data_used_space_vc1" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_data_used_space_vc2" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_data_used_space_vc3" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_header_credit_vc0" value="112"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_header_credit_vc1" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_header_credit_vc2" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_header_credit_vc3" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_header_used_space_vc0" value="1792"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_header_used_space_vc1" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_header_used_space_vc2" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_header_used_space_vc3" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_completion_timeout" value="ABCD"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_custom_phy_x8" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_custom_rx_buffer_xml" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_device_id" value="0x1BE7"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_disable_L0s" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_dll_active_report_support" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_eie_b4_nfts_count" value="4"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_enable_completion_timeout_disable" value="1"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_enable_function_msix_support" value="1"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_enable_hip" value="1"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_enable_hip_core_clk" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_enable_pcie_gen2_x8_es" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_enable_pcie_gen2_x8_s5gx" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_enable_root_port_endpoint_mode" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_enable_simple_dma" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_enable_slot_capability" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_enable_tl_bypass_mode" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_endpoint_L0s_acceptable_latency" value="&lt;64 ns"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_endpoint_L1_acceptable_latency" value="&lt;1 us"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_exp_rom_bar_size" value="N/A"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_gen2_nfts_diff_clock" value="255"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_gen2_nfts_same_clock" value="255"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_initiator_performance_preset" value="Maximum"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_internal_clock" value="125 MHz"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_io_base_and_limit_register" value="IODisable"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_lanerev" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_link_port_number" value="0x01"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_max_payload_size" value="512 Bytes"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_mem_base_and_limit_register" value="MemDisable"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_msix_pba_bir" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_msix_pba_offset" value="62"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_msix_table_bir" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_msix_table_offset" value="64"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_msix_table_size" value="16"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nonposted_data_credit_vc0" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nonposted_data_credit_vc1" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nonposted_data_credit_vc2" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nonposted_data_credit_vc3" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nonposted_data_used_space_vc0" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nonposted_data_used_space_vc1" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nonposted_data_used_space_vc2" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nonposted_data_used_space_vc3" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nonposted_header_credit_vc0" value="54"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nonposted_header_credit_vc1" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nonposted_header_credit_vc2" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nonposted_header_credit_vc3" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nonposted_header_used_space_vc0" value="864"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nonposted_header_used_space_vc1" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nonposted_header_used_space_vc2" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_nonposted_header_used_space_vc3" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_number_of_lanes" value="x8"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_phy_interface" value="Serial"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_pme_pending" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_pme_reg_id" value="0x0000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_posted_data_credit_vc0" value="360"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_posted_data_credit_vc1" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_posted_data_credit_vc2" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_posted_data_credit_vc3" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_posted_data_used_space_vc0" value="5760"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_posted_data_used_space_vc1" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_posted_data_used_space_vc2" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_posted_data_used_space_vc3" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_posted_header_credit_vc0" value="50"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_posted_header_credit_vc1" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_posted_header_credit_vc2" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_posted_header_credit_vc3" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_posted_header_used_space_vc0" value="800"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_posted_header_used_space_vc1" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_posted_header_used_space_vc2" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_posted_header_used_space_vc3" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_rate" value="Gen2 (5.0 Gbps)"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_retry_buffer_size" value="16 KBytes"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_revision_id" value="0x01"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_rx_buffer_preset" value="Default"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_rx_buffer_size_string_vc0" value="16 KBytes"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_rx_buffer_size_string_vc1" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_rx_buffer_size_string_vc2" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_rx_buffer_size_string_vc3" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_rx_buffer_size_vc0" value="16384"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_rx_buffer_size_vc1" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_rx_buffer_size_vc2" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_rx_buffer_size_vc3" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_slot_capabilities" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_special_phy_gl" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_special_phy_px" value="1"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_subsystem_device_id" value="0x1BE7"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_subsystem_vendor_id" value="0xC100"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_surprise_down_error_support" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_target_performance_preset" value="Maximum"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_test_out_width" value="None"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_threshold_for_L0s_entry" value="8192 ns"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_total_header_credit_vc0" value="216"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_total_header_credit_vc1" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_total_header_credit_vc2" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_total_header_credit_vc3" value="0"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_txrx_clock" value="100 MHz"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_underSOPCBuilder" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_use_crc_forwarding" value="0"  type="BOOLEAN"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_use_parity" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_variation_name" value="siv_gen2x8_core"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_vendor_id" value="0xC100"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_version" value="2.0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_pcie_virutal_channels" value="1"  type="INTEGER"  enable="1" />
// Retrieval info:      <PRIVATE name = "pref_nonp_independent" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "translationTableSizeInfo" value="The bridge reserves a contiguous Avalon address range to access
// Retrieval info: PCIe devices. This Avalon address range is segmented into one or
// Retrieval info: more equal-sized pages that are individually mapped to PCIe
// Retrieval info: addresses. Select the number and size of the address pages."  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWAddress0" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWAddress1" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWAddress10" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWAddress11" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWAddress12" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWAddress13" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWAddress14" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWAddress15" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWAddress2" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWAddress3" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWAddress4" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWAddress5" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWAddress6" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWAddress7" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWAddress8" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWAddress9" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWPCIAddress0" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWPCIAddress1" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWPCIAddress10" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWPCIAddress11" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWPCIAddress12" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWPCIAddress13" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWPCIAddress14" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWPCIAddress15" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWPCIAddress2" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWPCIAddress3" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWPCIAddress4" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWPCIAddress5" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWPCIAddress6" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWPCIAddress7" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWPCIAddress8" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonHWPCIAddress9" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiAvalonTranslationTable" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiBar0PCIAddress" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiBar0Prefetchable" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiBar1PCIAddress" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiBar1Prefetchable" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiBar2PCIAddress" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiBar2Prefetchable" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiBar3PCIAddress" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiBar3Prefetchable" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiBar4PCIAddress" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiBar4Prefetchable" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiBar5PCIAddress" value="0x00000000"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiBar5Prefetchable" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiCRAInfoPanel" value="other"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiExpROMType" value="Select to Enable"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiFixedTable" value="true"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiPCIBar0Type" value="64-bit Prefetchable Memory"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiPCIBar1Type" value="N/A"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiPCIBar2Type" value="64-bit Prefetchable Memory"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiPCIBar3Type" value="N/A"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiPCIBar4Type" value="Disable this and all higher BARs"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiPCIBar5Type" value="Disable this and all higher BARs"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiPCIBarTable" value="false"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiPCIBusArbiter" value="external"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiPCIDeviceMode" value="masterTarget"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiPCIMasterPerformance" value="burstSinglePending"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiPCITargetPerformance" value="burstSinglePending"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiPaneCount" value="1"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "uiPaneSize" value="20"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "ui_pcie_msix_pba_bir" value="1:0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "ui_pcie_msix_table_bir" value="1:0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "p_tx_cdc_full_value" value="12"  type="INTEGER"  enable="1" />
// Retrieval info:     </NAMESPACE>
// Retrieval info:     <NAMESPACE name = "simgen_enable">
// Retrieval info:      <PRIVATE name = "language" value="VERILOG"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "enabled" value="0"  type="STRING"  enable="1" />
// Retrieval info:     </NAMESPACE>
// Retrieval info:     <NAMESPACE name = "greybox">
// Retrieval info:      <PRIVATE name = "gb_enabled" value="0"  type="STRING"  enable="1" />
// Retrieval info:      <PRIVATE name = "filename" value="siv_gen2x8_syn.v"  type="STRING"  enable="1" />
// Retrieval info:     </NAMESPACE>
// Retrieval info:     <NAMESPACE name = "testbench">
// Retrieval info:      <PRIVATE name = "plugin_worker" value="1"  type="STRING"  enable="1" />
// Retrieval info:     </NAMESPACE>
// Retrieval info:     <NAMESPACE name = "simgen">
// Retrieval info:      <PRIVATE name = "filename" value="siv_gen2x8_core.v"  type="STRING"  enable="1" />
// Retrieval info:     </NAMESPACE>
// Retrieval info:     <NAMESPACE name = "serializer"/>
// Retrieval info:    </PRIVATES>
// Retrieval info:    <FILES/>
// Retrieval info:    <PORTS/>
// Retrieval info:    <LIBRARIES/>
// Retrieval info:   </STATIC_SECTION>
// Retrieval info:  </NETLIST_SECTION>
// Retrieval info: </MEGACORE>
// =========================================================
