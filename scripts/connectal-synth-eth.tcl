source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

# PMA-Direct Transceiver, No PCS
proc create_altera_10gbe_pma {channels} {
    set core_name {altera_xcvr_native_sv}
    set core_version {14.0}
    set ip_name {altera_xcvr_native_sv_wrapper}

	set params [ dict create ]

    dict set params tx_enable                           1
    dict set params rx_enable                           1
    dict set params enable_std                          0
    dict set params enable_teng                         0
    dict set params data_path_select                    "pma_direct"
    dict set params channels                            4
    dict set params bonded_mode                         "non_bonded"
    dict set params enable_simple_interface             1
    dict set params set_data_rate                       "10312.5"
    dict set params pma_direct_width                    40
    dict set params tx_pma_clk_div                      1
    dict set params pll_reconfig_enable                 0
    dict set params pll_external_enable                 0
    dict set params plls                                1
    dict set params pll_select                          0
    dict set params pll_refclk_cnt                      1
    dict set params gui_pll_reconfig_pll0_pll_type      "CMU"
    dict set params gui_pll_reconfig_pll1_pll_type      "CMU"
    dict set params gui_pll_reconfig_pll2_pll_type      "CMU"
    dict set params gui_pll_reconfig_pll3_pll_type      "CMU"
    dict set params gui_pll_reconfig_pll0_data_rate     "1250"
    dict set params gui_pll_reconfig_pll1_data_rate     "1250"
    dict set params gui_pll_reconfig_pll2_data_rate     "1250"
    dict set params gui_pll_reconfig_pll3_data_rate     "1250"
    dict set params gui_pll_reconfig_pll0_refclk_freq   "644.53125 MHz"
    dict set params gui_pll_reconfig_pll1_refclk_freq   "125.0"
    dict set params gui_pll_reconfig_pll2_refclk_freq   "125.0"
    dict set params gui_pll_reconfig_pll3_refclk_freq   "125.0"
    dict set params gui_pll_reconfig_pll0_refclk_sel    0
    dict set params gui_pll_reconfig_pll1_refclk_sel    0
    dict set params gui_pll_reconfig_pll2_refclk_sel    0
    dict set params gui_pll_reconfig_pll3_refclk_sel    0
    dict set params gui_pll_reconfig_pll0_clk_network   "x1"
    dict set params gui_pll_reconfig_pll1_clk_network   "x1"
    dict set params gui_pll_reconfig_pll2_clk_network   "x1"
    dict set params gui_pll_reconfig_pll3_clk_network   "x1"
    dict set params cdr_reconfig_enable                 0
    dict set params cdr_refclk_cnt                      1
    dict set params cdr_refclk_select                   0
    dict set params set_cdr_refclk_freq                 "644.53125 MHz"
    dict set params rx_ppm_detect_threshold             100
    dict set params enable_port_tx_pma_qpipullup        0
    dict set params enable_port_tx_pma_qpipulldn        0
    dict set params enable_port_tx_pma_txdetectrx       0
    dict set params enable_port_tx_pma_rxfound          0
    dict set params enable_port_tx_pma_pclk             0
    dict set params enable_port_rx_pma_qpipulldn        0
    dict set params enable_port_rx_pma_clkout           1
    dict set params enable_port_rx_pma_pclk             0
    dict set params enable_port_rx_is_lockedtodata      1
    dict set params enable_port_rx_is_lockedtoref       1
    dict set params enable_ports_rx_manual_cdr_mode     0
    dict set params rx_clkslip_enable                   0
    dict set params enable_port_rx_signaldetect         0
    dict set params enable_port_rx_seriallpbken         1
    dict set params std_protocol_hint                   "basic"
    dict set params std_pcs_pma_width                   10
    dict set params std_low_latency_bypass_enable       0
    dict set params std_tx_pcfifo_mode                  "low_latency"
    dict set params std_rx_pcfifo_mode                  "low_latency"
    dict set params enable_port_tx_std_pcfifo_full      0
    dict set params enable_port_tx_std_pcfifo_empty     0
    dict set params enable_port_rx_std_pcfifo_full      0
    dict set params enable_port_rx_std_pcfifo_empty     0
    dict set params std_rx_byte_order_enable            0
    dict set params std_rx_byte_order_mode              "manual"
    dict set params std_rx_byte_order_symbol_count      1
    dict set params std_rx_byte_order_pattern           0
    dict set params std_rx_byte_order_pad               0
    dict set params enable_port_rx_std_byteorder_ena    0
    dict set params enable_port_rx_std_byteorder_flag   0
    dict set params std_tx_byte_ser_enable              0
    dict set params std_rx_byte_deser_enable            0
    dict set params std_tx_8b10b_enable                 0
    dict set params std_tx_8b10b_disp_ctrl_enable       0
    dict set params std_rx_8b10b_enable                 0
    dict set params std_rx_rmfifo_enable                0
    dict set params std_rx_rmfifo_pattern_p             00000
    dict set params std_rx_rmfifo_pattern_n             00000
    dict set params enable_port_rx_std_rmfifo_full      0
    dict set params enable_port_rx_std_rmfifo_empty     0
    dict set params std_tx_bitslip_enable               0
    dict set params enable_port_tx_std_bitslipboundarysel           0
    dict set params std_rx_word_aligner_mode            "bit_slip"
    dict set params std_rx_word_aligner_pattern_len     7
    dict set params std_rx_word_aligner_pattern         0000000000
    dict set params std_rx_word_aligner_rknumber        3
    dict set params std_rx_word_aligner_renumber        3
    dict set params std_rx_word_aligner_rgnumber        3
    dict set params std_rx_run_length_val               0
    dict set params enable_port_rx_std_wa_patternalign  0
    dict set params enable_port_rx_std_wa_a1a2size           0
    dict set params enable_port_rx_std_bitslipboundarysel    0
    dict set params enable_port_rx_std_bitslip          0
    dict set params enable_port_rx_std_runlength_err    0
    dict set params std_tx_bitrev_enable                0
    dict set params std_rx_bitrev_enable                0
    dict set params std_tx_byterev_enable               0
    dict set params std_rx_byterev_enable               0
    dict set params std_tx_polinv_enable                0
    dict set params std_rx_polinv_enable                0
    dict set params enable_port_rx_std_bitrev_ena       0
    dict set params enable_port_rx_std_byterev_ena      0
    dict set params enable_port_tx_std_polinv           0
    dict set params enable_port_rx_std_polinv           0
    dict set params enable_port_tx_std_elecidle         0
    dict set params enable_port_rx_std_signaldetect     0
    dict set params enable_port_rx_std_prbs_status      0
    dict set params teng_protocol_hint                  "basic"
    dict set params teng_pcs_pma_width                  40
    dict set params teng_pld_pcs_width                  40
    dict set params teng_txfifo_mode                    "phase_comp"
    dict set params teng_txfifo_full                    31
    dict set params teng_txfifo_empty                   0
    dict set params teng_txfifo_pfull                   23
    dict set params teng_txfifo_pempty                  2
    dict set params enable_port_tx_10g_fifo_full        0
    dict set params enable_port_tx_10g_fifo_pfull       0
    dict set params enable_port_tx_10g_fifo_empty       0
    dict set params enable_port_tx_10g_fifo_pempty      0
    dict set params enable_port_tx_10g_fifo_del         0
    dict set params enable_port_tx_10g_fifo_insert      0
    dict set params teng_rxfifo_mode                    "phase_comp"
    dict set params teng_rxfifo_full                    31
    dict set params teng_rxfifo_empty                   0
    dict set params teng_rxfifo_pfull                   23
    dict set params teng_rxfifo_pempty                  7
    dict set params teng_rxfifo_align_del               0
    dict set params teng_rxfifo_control_del             0
    dict set params enable_port_rx_10g_data_valid       0
    dict set params enable_port_rx_10g_fifo_full        0
    dict set params enable_port_rx_10g_fifo_pfull       0
    dict set params enable_port_rx_10g_fifo_empty       0
    dict set params enable_port_rx_10g_fifo_pempty      0
    dict set params enable_port_rx_10g_fifo_del         0
    dict set params enable_port_rx_10g_fifo_insert      0
    dict set params enable_port_rx_10g_fifo_rd_en       0
    dict set params enable_port_rx_10g_fifo_align_val   0
    dict set params enable_port_rx_10g_fifo_align_clr   0
    dict set params enable_port_rx_10g_fifo_align_en    0
    dict set params enable_port_rx_10g_clk33out         0
    dict set params teng_tx_frmgen_user_length          2048
    dict set params teng_tx_frmgen_burst_enable         0
    dict set params enable_port_tx_10g_frame            0
    dict set params enable_port_tx_10g_frame_diag_status       0
    dict set params enable_port_tx_10g_frame_burst_en          0
    dict set params teng_rx_frmsync_user_length         2048
    dict set params enable_port_rx_10g_frame            0
    dict set params enable_port_rx_10g_frame_lock       0
    dict set params enable_port_rx_10g_frame_mfrm_err   0
    dict set params enable_port_rx_10g_frame_sync_err   0
    dict set params enable_port_rx_10g_frame_pyld_ins   0
    dict set params enable_port_rx_10g_frame_skip_ins   0
    dict set params enable_port_rx_10g_frame_skip_err   0
    dict set params enable_port_rx_10g_frame_diag_err   0
    dict set params enable_port_rx_10g_frame_diag_status   0
    dict set params teng_tx_sh_err                         0
    dict set params enable_port_rx_10g_crc32_err           0
    dict set params enable_port_rx_10g_highber             0
    dict set params enable_port_rx_10g_highber_clr_cnt     0
    dict set params enable_port_rx_10g_clr_errblk_count    0
    dict set params teng_tx_scram_user_seed                000000000000000
    dict set params enable_port_rx_10g_descram_err         0
    dict set params enable_port_rx_10g_blk_lock            0
    dict set params enable_port_rx_10g_blk_sh_err          0
    dict set params teng_tx_polinv_enable                  0
    dict set params teng_tx_bitslip_enable                 0
    dict set params teng_rx_polinv_enable                  0
    dict set params teng_rx_bitslip_enable                 0
    dict set params enable_port_tx_10g_bitslip             0
    dict set params enable_port_rx_10g_bitslip             0
    dict set params enable_port_rx_teng_prbs_status        0

    set component_parameters {}
	foreach item [dict keys $params] {
		set val [dict get $params $item]
		lappend component_parameters --component-parameter=$item=$val
	}

    connectal_altera_synth_ip $core_name $core_version $ip_name $component_parameters
}

proc create_xcvr_reset {channels} {
    set core_name {altera_xcvr_reset_control}
    set core_version {14.0}
    set ip_name {altera_xcvr_reset_control_wrapper}

	dict set params CHANNELS              $channels
	dict set params PLLS                  4
	dict set params SYS_CLK_IN_MHZ        125
	dict set params SYNCHRONIZE_RESET     1
	dict set params REDUCED_SIM_TIME      1
	dict set params TX_PLL_ENABLE         1
	dict set params T_PLL_POWERDOWN       1000
	dict set params SYNCHRONIZE_PLL_RESET 0
	dict set params TX_ENABLE             1
	dict set params TX_PER_CHANNEL        0
	dict set params T_TX_DIGITALRESET     20
	dict set params T_PLL_LOCK_HYST       0
	dict set params RX_ENABLE             1
	dict set params RX_PER_CHANNEL        0
	dict set params T_RX_ANALOGRESET      40
	dict set params T_RX_DIGITALRESET     4000

    set component_parameters {}
	foreach item [dict keys $params] {
		set val [dict get $params $item]
		lappend component_parameters --component-parameter=$item=$val
	}

    connectal_altera_synth_ip $core_name $core_version $ip_name $component_parameters
}

if {$NUMBER_OF_10G_PORTS != ""} {
set v [expr "$NUMBER_OF_10G_PORTS * 2"]
create_altera_10gbe_pma $NUMBER_OF_10G_PORTS
create_xcvr_reconfig alt_xcvr_reconfig 14.0 altera_xgbe_pma_reconfig_wrapper $v
create_xcvr_reset $NUMBER_OF_10G_PORTS
}
