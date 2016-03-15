######################################################################################################
##  File name :       default.xdc
##
##  Details :     Constraints file
##                    FPGA family:       virtex7
##                    FPGA:              xc7vx690t-3ffg1761C
##                    Speedgrade:        -3
##
######################################################################################################

##The following two properties should be set for every design
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

######################################################################################################
# PIN ASSIGNMENTS
######################################################################################################
set_property LOC AB6  [get_ports { CLK_pci_sys_clk_n }]
set_property LOC AB5  [get_ports { CLK_pci_sys_clk_p }]
set_property LOC K225 [get_ports { RST_N_pci_sys_reset_n }]
set_property LOC AK17  [get_ports { CLK_sys_clk_p }] // 300MHz SYSCLK
set_property LOC AK16 [get_ports { CLK_sys_clk_n }]  // 300MHz SYSCLK

######################################################################################################
# I/O STANDARDS
######################################################################################################
set_property IOSTANDARD LVCMOS18    [get_ports { leds_leds[*] }]
set_property IOSTANDARD DIFF_SSTL12 [get_ports { CLK_sys_clk_* }]
set_property IOSTANDARD LVCMOS18    [get_ports { RST_N_pci_sys_reset_n }]
set_property PULLUP     true        [get_ports { RST_N_pci_sys_reset_n }]

######################################################################################################
# TIMING CONSTRAINTS
######################################################################################################

## in pcie-clocks.xdc

