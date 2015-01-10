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

proc create_pcie_sv_hip_ast {} {
    global boardname
    set pcieversion {2.1}
    set maxlinkwidth {x8}
    set core_name {altera_pcie_sv_hip_ast}
    set core_version {14.0}
    set ip_name {altera_pcie_sv_hip_ast_wrapper}

    set vendor_id {0x1172}
    set device_id {0xee01}
    set class_code {0xff0000}

	set params [ dict create ]
	dict set params lane_mask_hwtcl                      $maxlinkwidth
	dict set params gen123_lane_rate_mode_hwtcl          "Gen2 (5.0 Gbps)"
	dict set params port_type_hwtcl                      "Native endpoint"
	dict set params pcie_spec_version_hwtcl              $pcieversion
	dict set params ast_width_hwtcl                      "Avalon-ST 128-bit"
	dict set params rxbuffer_rxreq_hwtcl                 "Low"
	dict set params pll_refclk_freq_hwtcl                "100 MHz"
	dict set params set_pld_clk_x1_625MHz_hwtcl          0
    # use_rx_be_hwtcl is a deprecated signal
	dict set params use_rx_st_be_hwtcl                   1
	dict set params use_ast_parity                       0
	dict set params multiple_packets_per_cycle_hwtcl     0
	dict set params in_cvp_mode_hwtcl                    0
	dict set params use_tx_cons_cred_sel_hwtcl           0
	dict set params use_config_bypass_hwtcl              0
	dict set params hip_reconfig_hwtcl                   0
	dict set params hip_tag_checking_hwtcl               1
	dict set params enable_power_on_rst_pulse_hwtcl      0

	dict set params bar0_type_hwtcl                      1
	dict set params bar0_size_mask_hwtcl                 28
	dict set params bar0_io_space_hwtcl                  "Disabled"
	dict set params bar0_64bit_mem_space_hwtcl           "Enabled"

	dict set params bar1_type_hwtcl                      0
	dict set params bar1_size_mask_hwtcl                 0
	dict set params bar1_io_space_hwtcl                  "Disabled"
	dict set params bar1_prefetchable_hwtcl              "Disabled"

	dict set params bar2_type_hwtcl                      1
	dict set params bar2_size_mask_hwtcl                 10
	dict set params bar2_io_space_hwtcl                  "Disabled"
	dict set params bar2_64bit_mem_space_hwtcl           "Disabled"
	dict set params bar2_prefetchable_hwtcl              "Disabled"

	dict set params bar3_type_hwtcl                          0
	dict set params	bar3_size_mask_hwtcl                     0
	dict set params	bar3_io_space_hwtcl                      "Disabled"
	dict set params	bar3_prefetchable_hwtcl                  "Disabled"

	dict set params	bar4_size_mask_hwtcl                     0
	dict set params	bar4_io_space_hwtcl                      "Disabled"
	dict set params	bar4_64bit_mem_space_hwtcl               "Disabled"
	dict set params	bar4_prefetchable_hwtcl                  "Disabled"

	dict set params	bar5_size_mask_hwtcl                     0
	dict set params	bar5_io_space_hwtcl                      "Disabled"
	dict set params	bar5_prefetchable_hwtcl                  "Disabled"
	dict set params	expansion_base_address_register_hwtcl    0
	dict set params	io_window_addr_width_hwtcl               0
	dict set params	prefetchable_mem_window_addr_width_hwtcl 0

	dict set params	vendor_id_hwtcl                          $vendor_id
	dict set params	device_id_hwtcl                          $device_id
	dict set params	revision_id_hwtcl                        1
	dict set params	class_code_hwtcl                         $class_code
	dict set params	subsystem_vendor_id_hwtcl                $vendor_id
	dict set params	subsystem_device_id_hwtcl                $device_id
	dict set params	max_payload_size_hwtcl                   256
	dict set params	extend_tag_field_hwtcl                   "32"
	dict set params	completion_timeout_hwtcl                 "ABCD"
	dict set params	enable_completion_timeout_disable_hwtcl  1

	set component_parameters {}
	foreach item [dict keys $params] {
		set val [dict get $params $item]
		lappend component_parameters --component-parameter=$item=$val
	}

    fpgamake_altera_ipcore $core_name $core_version $ip_name $component_parameters
}

proc create_pcie_reconfig {} {
    set core_name {altera_pcie_reconfig_driver}
    set core_version {14.0}
    set ip_name {altera_pcie_reconfig_driver_wrapper}

    set params [ dict create ]

	set component_parameters {}
	foreach item [dict keys $params ] {
		set val [dict get $params $item]
		lappend component_parameters --component-parameter=$item=$val
	}

    fpgamake_altera_ipcore $core_name $core_version $ip_name $component_parameters
}

if $need_altera_pcie {
    create_pcie_sv_hip_ast
    create_xcvr_reconfig alt_xcvr_reconfig 14.0 alt_xcvr_reconfig_wrapper 10
    create_pcie_reconfig
}

