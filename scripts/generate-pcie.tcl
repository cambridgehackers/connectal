create_project proj_pcie ./proj_pcie -part xc7vx485tffg1761-2

if {[lsearch -exact [get_boards] {xilinx.com:virtex7:vc707:2.0}] >= 0} {
    set_property board xilinx.com:virtex7:vc707:2.0 [current_project]
} else {
    set_property board xilinx.com:virtex7:vc707:1.1 [current_project]
}
create_ip -name pcie_7x -version 2.1 -vendor xilinx.com -library ip -module_name pcie_7x_0
generate_target instantiation_template [get_files  ./proj_pcie/proj_pcie.srcs/sources_1/ip/pcie_7x_0/pcie_7x_0.xci] -force
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
generate_target all [get_files  ./proj_pcie/proj_pcie.srcs/sources_1/ip/pcie_7x_0/pcie_7x_0.xci]
