#-----------------------------------------------------------
# Vivado v2016.2 (64-bit)
# SW Build 1577090 on Thu Jun  2 16:32:35 MDT 2016
# IP Build 1577682 on Fri Jun  3 12:00:54 MDT 2016
# Start of session at: Tue Aug  2 13:39:27 2016
# Process ID: 17294
# Current directory: /home/jamey/connectal/tests/nvme_strstr
# Command line: vivado
# Log file: /home/jamey/connectal/tests/nvme_strstr/vivado.log
# Journal file: /home/jamey/connectal/tests/nvme_strstr/vivado.jou
#-----------------------------------------------------------
start_gui
create_project accel /home/jamey/connectal/tests/nvme_strstr/accel -part xc7vx485tffg1157-1
add_files -norecurse /home/jamey/connectal/tests/nvme_strstr/miniitx100/verilog/mkNvmeAccelerator.v
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
ipx::package_project -root_dir /home/jamey/connectal/tests/nvme_strstr/miniitx100 -vendor user.org -library user -taxonomy /UserIP
ipx::add_port_map TREADY [ipx::get_bus_interfaces dataOut -of_objects [ipx::current_core]]
ipx::add_port_map TVALID [ipx::get_bus_interfaces dataOut -of_objects [ipx::current_core]]
ipx::add_port_map TLAST [ipx::get_bus_interfaces dataOut -of_objects [ipx::current_core]]
ipx::add_port_map TDATA [ipx::get_bus_interfaces dataOut -of_objects [ipx::current_core]]
ipx::add_port_map TKEEP [ipx::get_bus_interfaces dataOut -of_objects [ipx::current_core]]
set_property physical_name dataOut_tready_v [ipx::get_port_maps TREADY -of_objects [ipx::get_bus_interfaces dataOut -of_objects [ipx::current_core]]]
set_property physical_name dataOut_tvalid [ipx::get_port_maps TVALID -of_objects [ipx::get_bus_interfaces dataOut -of_objects [ipx::current_core]]]
set_property physical_name dataOut_tlast [ipx::get_port_maps TLAST -of_objects [ipx::get_bus_interfaces dataOut -of_objects [ipx::current_core]]]
set_property physical_name dataOut_tdata [ipx::get_port_maps TDATA -of_objects [ipx::get_bus_interfaces dataOut -of_objects [ipx::current_core]]]
set_property physical_name dataOut_tkeep [ipx::get_port_maps TKEEP -of_objects [ipx::get_bus_interfaces dataOut -of_objects [ipx::current_core]]]
ipx::associate_bus_interfaces -busif dataOut -clock CLK [ipx::current_core]
ipx::add_port_map TREADY [ipx::get_bus_interfaces msgOut -of_objects [ipx::current_core]]
set_property physical_name msgOut_tready_v [ipx::get_port_maps TREADY -of_objects [ipx::get_bus_interfaces msgOut -of_objects [ipx::current_core]]]
ipx::add_bus_interface msgIn [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:axis_rtl:1.0 [ipx::get_bus_interfaces msgIn -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:axis:1.0 [ipx::get_bus_interfaces msgIn -of_objects [ipx::current_core]]
ipx::add_port_map TVALID [ipx::get_bus_interfaces msgIn -of_objects [ipx::current_core]]
set_property physical_name msgIn_tvalid_v [ipx::get_port_maps TVALID -of_objects [ipx::get_bus_interfaces msgIn -of_objects [ipx::current_core]]]
ipx::add_port_map TLAST [ipx::get_bus_interfaces msgIn -of_objects [ipx::current_core]]
set_property physical_name msgIn_tlast_v [ipx::get_port_maps TLAST -of_objects [ipx::get_bus_interfaces msgIn -of_objects [ipx::current_core]]]
ipx::add_port_map TDATA [ipx::get_bus_interfaces msgIn -of_objects [ipx::current_core]]
set_property physical_name msgIn_tdata_v [ipx::get_port_maps TDATA -of_objects [ipx::get_bus_interfaces msgIn -of_objects [ipx::current_core]]]
ipx::add_port_map TKEEP [ipx::get_bus_interfaces msgIn -of_objects [ipx::current_core]]
set_property physical_name msgIn_tkeep_v [ipx::get_port_maps TKEEP -of_objects [ipx::get_bus_interfaces msgIn -of_objects [ipx::current_core]]]
ipx::add_port_map TREADY [ipx::get_bus_interfaces msgIn -of_objects [ipx::current_core]]
set_property physical_name msgIn_tready [ipx::get_port_maps TREADY -of_objects [ipx::get_bus_interfaces msgIn -of_objects [ipx::current_core]]]
ipx::associate_bus_interfaces -busif msgIn -clock CLK [ipx::current_core]
ipx::associate_bus_interfaces -busif msgOut -clock CLK [ipx::current_core]
ipx::associate_bus_interfaces -busif dataOut -clock CLK [ipx::current_core]
ipx::infer_bus_interface RST_N xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]
ipx::add_bus_interface nvme_pcie_mgt [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 [ipx::get_bus_interfaces nvme_pcie_mgt -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:pcie_7x_mgt:1.0 [ipx::get_bus_interfaces nvme_pcie_mgt -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces nvme_pcie_mgt -of_objects [ipx::current_core]]
ipx::add_port_map rxn [ipx::get_bus_interfaces nvme_pcie_mgt -of_objects [ipx::current_core]]
set_property physical_name pins_pcie_exp_rxn_v [ipx::get_port_maps rxn -of_objects [ipx::get_bus_interfaces nvme_pcie_mgt -of_objects [ipx::current_core]]]
ipx::add_port_map txn [ipx::get_bus_interfaces nvme_pcie_mgt -of_objects [ipx::current_core]]
set_property physical_name pins_pcie_exp_txn [ipx::get_port_maps txn -of_objects [ipx::get_bus_interfaces nvme_pcie_mgt -of_objects [ipx::current_core]]]
ipx::add_port_map rxp [ipx::get_bus_interfaces nvme_pcie_mgt -of_objects [ipx::current_core]]
set_property physical_name pins_pcie_exp_rxp_v [ipx::get_port_maps rxp -of_objects [ipx::get_bus_interfaces nvme_pcie_mgt -of_objects [ipx::current_core]]]
ipx::add_port_map txp [ipx::get_bus_interfaces nvme_pcie_mgt -of_objects [ipx::current_core]]
set_property physical_name pins_pcie_exp_txp [ipx::get_port_maps txp -of_objects [ipx::get_bus_interfaces nvme_pcie_mgt -of_objects [ipx::current_core]]]
ipx::add_bus_interface pcie_ref_clk [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:diff_clock_rtl:1.0 [ipx::get_bus_interfaces pcie_ref_clk -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:diff_clock:1.0 [ipx::get_bus_interfaces pcie_ref_clk -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces pcie_ref_clk -of_objects [ipx::current_core]]
set_property interface_mode slave [ipx::get_bus_interfaces pcie_ref_clk -of_objects [ipx::current_core]]
ipx::add_port_map CLK_P [ipx::get_bus_interfaces pcie_ref_clk -of_objects [ipx::current_core]]
set_property physical_name pins_pcie_refclk_p [ipx::get_port_maps CLK_P -of_objects [ipx::get_bus_interfaces pcie_ref_clk -of_objects [ipx::current_core]]]
ipx::add_port_map CLK_N [ipx::get_bus_interfaces pcie_ref_clk -of_objects [ipx::current_core]]
set_property physical_name pins_pcie_refclk_n [ipx::get_port_maps CLK_N -of_objects [ipx::get_bus_interfaces pcie_ref_clk -of_objects [ipx::current_core]]]
ipx::add_bus_interface pcie_sys_reset_n [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:reset_rtl:1.0 [ipx::get_bus_interfaces pcie_sys_reset_n -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:reset:1.0 [ipx::get_bus_interfaces pcie_sys_reset_n -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces pcie_sys_reset_n -of_objects [ipx::current_core]]
ipx::add_port_map RST [ipx::get_bus_interfaces pcie_sys_reset_n -of_objects [ipx::current_core]]
set_property physical_name RST_N_pins_pcie_sys_reset_n [ipx::get_port_maps RST -of_objects [ipx::get_bus_interfaces pcie_sys_reset_n -of_objects [ipx::current_core]]]

set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
set_property  ip_repo_paths  /home/jamey/connectal/tests/nvme_strstr/miniitx100 [current_project]
update_ip_catalog
ipx::check_integrity -quiet [ipx::current_core]
#ipx::archive_core /home/jamey/connectal/tests/nvme_strstr/miniitx100/user.org_user_mkNvmeAccelerator_1.0.zip [ipx::current_core]
