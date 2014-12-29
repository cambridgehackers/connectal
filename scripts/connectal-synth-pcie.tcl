source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

if $need_xilinx_pcie {
    set pcieversion {3.0}
    set maxlinkwidth {X8}
    if {$boardname == {zc706}} {
	set maxlinkwidth {X4}
    }
    if {$boardname == {ac701}} {
	set maxlinkwidth {X4}
    }
    if {[version -short] == "2013.2"} {
	set pcieversion {2.1}
    }
    connectal_synth_ip pcie_7x $pcieversion pcie_7x_0 [list CONFIG.mode_selection {Advanced} CONFIG.ASPM_Optionality {true} CONFIG.Disable_Tx_ASPM_L0s {true} CONFIG.Buf_Opt_BMA {true} CONFIG.Bar0_64bit {true} CONFIG.Bar0_Size {16} CONFIG.Bar0_Scale {Kilobytes} CONFIG.Bar2_64bit {true} CONFIG.Bar2_Enabled {true} CONFIG.Bar2_Scale {Megabytes} CONFIG.Bar2_Size {1} CONFIG.Base_Class_Menu {Memory_controller} CONFIG.Device_ID {c100} CONFIG.IntX_Generation {false} CONFIG.MSI_Enabled {false} CONFIG.MSIx_Enabled {true} CONFIG.MSIx_PBA_Offset {1f0} CONFIG.MSIx_Table_Offset {200} CONFIG.MSIx_Table_Size {10} CONFIG.Maximum_Link_Width $maxlinkwidth CONFIG.Subsystem_ID {a705} CONFIG.Subsystem_Vendor_ID {1be7} CONFIG.Use_Class_Code_Lookup_Assistant {false} CONFIG.Vendor_ID {1be7} ]
# Description of MSIx_Table_Offset is in:
# Xilinx/Vivado/2013.2/data/ip/xilinx/pcie_7x_v2_1/xgui/pcie_7x_v2_1.tcl
# (it is byteoffset/8, expressed in hex)
}

if $need_altera_pcie {

	set altera_pcie_config [ dict create ]
	dict set altera_pcie_config lane_mask_hwtcl                      "x8"
	dict set altera_pcie_config gen123_lane_rate_mode_hwtcl          "Gen2 (5.0 Gbps)"
	dict set altera_pcie_config port_type_hwtcl                      "Native endpoint"
	dict set altera_pcie_config pcie_spec_version_hwtcl              "2.1"
	dict set altera_pcie_config ast_width_hwtcl                      "Avalon-ST 128-bit"
	dict set altera_pcie_config rxbuffer_rxreq_hwtcl                 "Low"
	dict set altera_pcie_config pll_refclk_freq_hwtcl                "100 MHz"
	dict set altera_pcie_config set_pld_clk_x1_625MHz_hwtcl          0
	dict set altera_pcie_config use_rx_st_be_hwtcl                   0
	dict set altera_pcie_config use_ast_parity                       0
	dict set altera_pcie_config multiple_packets_per_cycle_hwtcl     0
	dict set altera_pcie_config in_cvp_mode_hwtcl                    0
	dict set altera_pcie_config use_tx_cons_cred_sel_hwtcl           0
	dict set altera_pcie_config use_config_bypass_hwtcl              0
	dict set altera_pcie_config hip_reconfig_hwtcl                   0
	dict set altera_pcie_config hip_tag_checking_hwtcl               1
	dict set altera_pcie_config enable_power_on_rst_pulse_hwtcl      0

	dict set altera_pcie_config bar0_type_hwtcl                      1
	dict set altera_pcie_config bar0_size_mask_hwtcl                 28
	dict set altera_pcie_config bar0_io_space_hwtcl                  "Disabled"
	dict set altera_pcie_config bar0_64bit_mem_space_hwtcl           "Enabled"

	dict set altera_pcie_config bar1_type_hwtcl                      0
	dict set altera_pcie_config bar1_size_mask_hwtcl                 0
	dict set altera_pcie_config bar1_io_space_hwtcl                  "Disabled"
	dict set altera_pcie_config bar1_prefetchable_hwtcl              "Disabled"

	dict set altera_pcie_config bar2_type_hwtcl                      1
	dict set altera_pcie_config bar2_size_mask_hwtcl                 10
	dict set altera_pcie_config bar2_io_space_hwtcl                  "Disabled"
	dict set altera_pcie_config bar2_64bit_mem_space_hwtcl           "Disabled"
	dict set altera_pcie_config bar2_prefetchable_hwtcl              "Disabled"

	dict set altera_pcie_config bar3_type_hwtcl                          0
	dict set altera_pcie_config	bar3_size_mask_hwtcl                     0
	dict set altera_pcie_config	bar3_io_space_hwtcl                      "Disabled"
	dict set altera_pcie_config	bar3_prefetchable_hwtcl                  "Disabled"

	dict set altera_pcie_config	bar4_size_mask_hwtcl                     0
	dict set altera_pcie_config	bar4_io_space_hwtcl                      "Disabled"
	dict set altera_pcie_config	bar4_64bit_mem_space_hwtcl               "Disabled"
	dict set altera_pcie_config	bar4_prefetchable_hwtcl                  "Disabled"

	dict set altera_pcie_config	bar5_size_mask_hwtcl                     0
	dict set altera_pcie_config	bar5_io_space_hwtcl                      "Disabled"
	dict set altera_pcie_config	bar5_prefetchable_hwtcl                  "Disabled"
	dict set altera_pcie_config	expansion_base_address_register_hwtcl    0
	dict set altera_pcie_config	io_window_addr_width_hwtcl               0
	dict set altera_pcie_config	prefetchable_mem_window_addr_width_hwtcl 0

	dict set altera_pcie_config	vendor_id_hwtcl                          4466
	dict set altera_pcie_config	device_id_hwtcl                          57345
	dict set altera_pcie_config	revision_id_hwtcl                        1
	dict set altera_pcie_config	class_code_hwtcl                         16711680
	dict set altera_pcie_config	subsystem_vendor_id_hwtcl                4466
	dict set altera_pcie_config	subsystem_device_id_hwtcl                57345
	dict set altera_pcie_config	max_payload_size_hwtcl                   256
	dict set altera_pcie_config	extend_tag_field_hwtcl                   "32"
	dict set altera_pcie_config	completion_timeout_hwtcl                 "ABCD"
	dict set altera_pcie_config	enable_completion_timeout_disable_hwtcl  1

	set component_parameters {}
	foreach item [dict keys $altera_pcie_config] {
		set val [dict get $altera_pcie_config $item]
		lappend component_parameters --component-parameter=$item=$val
	}

	puts $component_parameters

    exec -ignorestderr -- ip-generate --project-directory=$ipdir/$boardname        \
            --output-directory=$ipdir/$boardname/synthesis                         \
            --file-set=QUARTUS_SYNTH                                               \
            --report-file=html:$ipdir/$boardname/$connectal_dut.html               \
            --report-file=sopcinfo:$ipdir/$boardname/$connectal_dut.sopcinfo       \
            --report-file=cmp:$ipdir/$boardname/$connectal_dut.cmp                 \
            --report-file=qip:$ipdir/$boardname/synthesis/$connectal_dut.qip       \
            --report-file=svd:$ipdir/$boardname/synthesis/$connectal_dut.svd       \
            --report-file=regmap:$ipdir/$boardname/synthesis/$connectal_dut.regmap \
            --report-file=xml:$ipdir/$boardname/$connectal_dut.xml                 \
            --system-info=DEVICE_FAMILY=StratixV                                   \
            --system-info=DEVICE=$partname                                         \
            --system-info=DEVICE_SPEEDGRADE=2_H2                                   \
            --language=VERILOG                                                     \
            {*}$component_parameters \
            --component-name=altera_pcie_sv_hip_ast


 	set altera_xcvr_reconfig_config [ dict create ]
	dict set altera_xcvr_reconfig_config number_of_reconfig_interfaces 10

	set component_parameters {}
	foreach item [dict keys $altera_xcvr_reconfig_config] {
		set val [dict get $altera_xcvr_reconfig_config $item]
		lappend component_parameters --component-parameter=$item=$val
	}

    exec -ignorestderr -- ip-generate --project-directory=$ipdir/$boardname        \
            --output-directory=$ipdir/$boardname/synthesis                         \
            --file-set=QUARTUS_SYNTH                                               \
            --report-file=html:$ipdir/$boardname/$connectal_dut.html               \
            --report-file=sopcinfo:$ipdir/$boardname/$connectal_dut.sopcinfo       \
            --report-file=cmp:$ipdir/$boardname/$connectal_dut.cmp                 \
            --report-file=qip:$ipdir/$boardname/synthesis/$connectal_dut.qip       \
            --report-file=svd:$ipdir/$boardname/synthesis/$connectal_dut.svd       \
            --report-file=regmap:$ipdir/$boardname/synthesis/$connectal_dut.regmap \
            --report-file=xml:$ipdir/$boardname/$connectal_dut.xml                 \
            --system-info=DEVICE_FAMILY=StratixV                                   \
            --system-info=DEVICE=$partname                                         \
            --system-info=DEVICE_SPEEDGRADE=2_H2                                   \
            --language=VERILOG                                                     \
            {*}$component_parameters \
            --component-name=alt_xcvr_reconfig

    set connectal_dut "altera_pcie_reconfig_driver"
    exec -ignorestderr -- ip-generate --project-directory=$ipdir/$boardname        \
            --output-directory=$ipdir/$boardname/synthesis                         \
            --file-set=QUARTUS_SYNTH                                               \
            --report-file=html:$ipdir/$boardname/$connectal_dut.html               \
            --report-file=sopcinfo:$ipdir/$boardname/$connectal_dut.sopcinfo       \
            --report-file=cmp:$ipdir/$boardname/$connectal_dut.cmp                 \
            --report-file=qip:$ipdir/$boardname/synthesis/$connectal_dut.qip       \
            --report-file=svd:$ipdir/$boardname/synthesis/$connectal_dut.svd       \
            --report-file=regmap:$ipdir/$boardname/synthesis/$connectal_dut.regmap \
            --report-file=xml:$ipdir/$boardname/$connectal_dut.xml                 \
            --system-info=DEVICE_FAMILY=StratixV                                   \
            --system-info=DEVICE=$partname                                         \
            --system-info=DEVICE_SPEEDGRADE=2_H2                                   \
            --language=VERILOG                                                     \
            --component-name=altera_pcie_reconfig_driver
}

