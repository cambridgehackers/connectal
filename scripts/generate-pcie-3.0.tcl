create_project -force project_pcie_kc705_2013.4 /scratch/jamey/project_pcie_kc705_2013.4 -part xc7k325tffg900-2
set_property board xilinx.com:kintex7:kc705:1.1 [current_project]
create_ip -name pcie_7x -version 3.0 -vendor xilinx.com -library ip -module_name pcie_7x_0
set_property -dict [list \
		    CONFIG.ASPM_Optionality {true} \
		    CONFIG.Bar0_64bit {true} \
		    CONFIG.Bar0_Size {8} \
		    CONFIG.Bar2_64bit {true} \
		    CONFIG.Bar2_Enabled {true} \
		    CONFIG.Bar2_Scale {Megabytes} \
		    CONFIG.Bar2_Size {1} \
		    CONFIG.Bar4_64bit {true} \
		    CONFIG.Bar4_Enabled {true} \
		    CONFIG.Bar4_Prefetchable {true} \
		    CONFIG.Bar4_Scale {Megabytes} \
		    CONFIG.Bar4_Size {1} \
		    CONFIG.Base_Class_Menu {Memory_controller} \
		    CONFIG.Device_ID {b100} \
		    CONFIG.IntX_Generation {false} \
		    CONFIG.MSI_Enabled {false} \
		    CONFIG.MSIx_Enabled {true} \
		    CONFIG.MSIx_PBA_Offset {a00} \
		    CONFIG.MSIx_Table_Offset {800} \
		    CONFIG.MSIx_Table_Size {10} \
		    CONFIG.Maximum_Link_Width {X8} \
		    CONFIG.Link_Speed {5.0_GT/s} \
		    CONFIG.Subsystem_ID {a705} \
		    CONFIG.Subsystem_Vendor_ID {1be7} \
		    CONFIG.Use_Class_Code_Lookup_Assistant {false} \
		    CONFIG.Vendor_ID {1be7} \
		    CONFIG.Xlnx_Ref_Board {KC705_REVC} \
		    CONFIG.en_transceiver_status_ports {false} \
		    CONFIG.mode_selection {Advanced} \
		   ] [get_ips pcie_7x_0]
generate_target {instantiation_template} [get_files /scratch/jamey/project_pcie_kc705_2013.4/project_pcie_kc705_2013.4.srcs/sources_1/ip/pcie_7x_0/pcie_7x_0.xci]
generate_target all [get_files  /scratch/jamey/project_pcie_kc705_2013.4/project_pcie_kc705_2013.4.srcs/sources_1/ip/pcie_7x_0/pcie_7x_0.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] /scratch/jamey/project_pcie_kc705_2013.4/project_pcie_kc705_2013.4.srcs/sources_1/ip/pcie_7x_0/pcie_7x_0.xci]
launch_run -jobs 16 pcie_7x_0_synth_1
open_example_project -force -dir /scratch/jamey/project_pcie_kc705_2013.4 [get_ips  pcie_7x_0]
