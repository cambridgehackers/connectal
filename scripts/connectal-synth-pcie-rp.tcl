source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"
source "$scriptsdir/../../fpgamake/tcl/ipcore.tcl"

if {$need_pcie == "x7_gen2x8"} {
connectal_synth_ip pcie_7x 3.0 pcie_7x_rp [list CONFIG.Device_Port_Type {Root_Port_of_PCI_Express_Root_Complex} CONFIG.Maximum_Link_Width {X8} CONFIG.Link_Speed {5.0_GT/s} CONFIG.PCIe_Cap_Slot_Implemented {true} CONFIG.Xlnx_Ref_Board {VC707} CONFIG.en_ext_pipe_interface {true}]
}

if {$need_pcie == "x7_gen3x8"} {
    if {[version -short] >= "2015.3"} {
	set pcieversion {4.1}
    } elseif {[version -short] >= "2015.2"} {
	set pcieversion {4.0}
    } else {
	set pcieversion {3.0}
    }
    set maxlinkwidth {X8}
    connectal_synth_ip pcie3_7x $pcieversion pcie3_7x_rp [list CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X8} CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {8.0_GT/s} CONFIG.axisten_if_enable_client_tag {false} CONFIG.AXISTEN_IF_RC_STRADDLE {false} CONFIG.pf0_bar0_size {8} CONFIG.PF0_DEV_CAP2_TPH_COMPLETER_SUPPORT {true} CONFIG.pf0_dsn_enabled {true} CONFIG.mode_selection {Advanced} CONFIG.pipe_mode_sim {Enable_External_PIPE_Interface} CONFIG.en_ext_clk {false} CONFIG.shared_logic_in_core {true} CONFIG.pcie_blk_locn {X0Y0} CONFIG.tandem_mode {None} CONFIG.axisten_if_width {256_bit} CONFIG.PF0_DEVICE_ID {7138} CONFIG.pf0_class_code_base {06} CONFIG.PF0_CLASS_CODE {068000} CONFIG.pf0_base_class_menu {Bridge_device} CONFIG.pf0_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} CONFIG.PF1_DEVICE_ID {7011} CONFIG.pf1_class_code_base {06} CONFIG.PF1_CLASS_CODE {068000} CONFIG.pf1_base_class_menu {Bridge_device} CONFIG.pf1_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} CONFIG.pf0_bar0_type {Memory} CONFIG.pf0_bar1_type {N/A} CONFIG.pf0_bar2_type {N/A} CONFIG.pf0_bar3_type {N/A} CONFIG.pf0_bar4_type {N/A} CONFIG.pf0_bar5_type {N/A} CONFIG.pf1_bar0_type {N/A} CONFIG.pf1_bar1_type {N/A} CONFIG.pf1_bar2_type {N/A} CONFIG.pf1_bar3_type {N/A} CONFIG.pf1_bar4_type {N/A} CONFIG.pf1_bar5_type {N/A} CONFIG.pf0_sriov_bar0_type {Memory} CONFIG.pf0_sriov_bar1_type {N/A} CONFIG.pf0_sriov_bar2_type {N/A} CONFIG.pf0_sriov_bar3_type {N/A} CONFIG.pf0_sriov_bar4_type {N/A} CONFIG.pf0_sriov_bar5_type {N/A} CONFIG.pf1_sriov_bar0_type {Memory} CONFIG.pf1_sriov_bar1_type {N/A} CONFIG.pf1_sriov_bar2_type {N/A} CONFIG.pf1_sriov_bar3_type {N/A} CONFIG.pf1_sriov_bar4_type {N/A} CONFIG.pf1_sriov_bar5_type {N/A} CONFIG.silicon_rev {Production} CONFIG.pipe_sim {false} CONFIG.axisten_freq {250} CONFIG.aspm_support {No_ASPM} CONFIG.en_ext_pipe_interface {true}]
}
