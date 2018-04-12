######################################################################################################
##  File name :       default.xdc
##
##  Details :     Constraints file
##                    FPGA family:       virtex7
##                    FPGA:              xc7vx485t-2ffg1761C
##                    Speedgrade:        -2
##
######################################################################################################

######################################################################################################
# PIN ASSIGNMENTS
######################################################################################################
set_property LOC AL9  [get_ports { CLK_pci_sys_clk_p }]
set_property LOC AL8  [get_ports { CLK_pci_sys_clk_n }]
set_property LOC AM17 [get_ports { RST_N_pci_sys_reset_n }]
set_property LOC G31  [get_ports { CLK_sys_clk1_300_p }]
set_property LOC F31  [get_ports { CLK_sys_clk1_300_n }]
set_property LOC G22  [get_ports { CLK_sys_clk2_300_p }]
set_property LOC G21  [get_ports { CLK_sys_clk2_300_n }]

set_property IOSTANDARD DIFF_SSTL12 [get_ports { CLK_sys_clk1_300_p }]
set_property IOSTANDARD DIFF_SSTL12 [get_ports { CLK_sys_clk1_300_n }]
set_property IOSTANDARD DIFF_SSTL12 [get_ports { CLK_sys_clk2_300_p }]
set_property IOSTANDARD DIFF_SSTL12 [get_ports { CLK_sys_clk2_300_n }]

set_property IOSTANDARD LVCMOS18    [get_ports { RST_N_pci_sys_reset_n }]
set_property PULLUP     true        [get_ports { RST_N_pci_sys_reset_n }]
