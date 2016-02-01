######################################################################################################
##  File name :       default.xdc
##
##  Details :     Constraints file
##                    FPGA family:       kintex7
##                    FPGA:              xc7k325t-2ffg900
##                    Speedgrade:        -2
##
######################################################################################################

######################################################################################################
# PIN ASSIGNMENTS
######################################################################################################

######################################################################################################
# I/O STANDARDS
######################################################################################################
set_property IOSTANDARD DIFF_SSTL15 [get_ports { CLK_pci_sys_clk_* }]
set_property IOSTANDARD DIFF_SSTL15 [get_ports { CLK_sys_clk_* }]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports { CLK_user_clk_* }]
set_property IOSTANDARD LVCMOS25    [get_ports { RST_N_pci_sys_reset_n }]
set_property PULLUP     true        [get_ports { RST_N_pci_sys_reset_n }]

######################################################################################################
# CELL LOCATIONS
######################################################################################################
#
# SYS clock 100 MHz (input) signal. The sys_clk_p and sys_clk_n
# signals are the PCI Express reference clock. Virtex-7 GT
# Transceiver architecture requires the use of a dedicated clock
# resources (FPGA input pins) associated with each GT Transceiver.
# To use these pins an IBUFDS primitive (refclk_ibuf) is
# instantiated in user's design.
# Please refer to the Virtex-7 GT Transceiver User Guide
# (UG) for guidelines regarding clock resource selection.
#
##set_property LOC IBUFDS_GTE2_X0Y1  [get_cells { *pci_clk_100mhz_buf }]

######################################################################################################
# TIMING CONSTRAINTS
######################################################################################################

## in pcie-clocks.xdc
