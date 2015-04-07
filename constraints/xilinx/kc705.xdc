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
set_property LOC U8   [get_ports { CLK_pci_sys_clk_p }]
set_property LOC U7   [get_ports { CLK_pci_sys_clk_n }]
set_property LOC G25  [get_ports { RST_N_pci_sys_reset_n }]
set_property LOC AD12 [get_ports { CLK_sys_clk_p }]
set_property LOC AD11 [get_ports { CLK_sys_clk_n }]
#set_property LOC K28  [get_ports { CLK_user_clk_p }]
#set_property LOC K29  [get_ports { CLK_user_clk_n }]

set_property LOC M6   [get_ports { PCIE_rxp_v[0] }]
set_property LOC P6   [get_ports { PCIE_rxp_v[1] }]
set_property LOC R4   [get_ports { PCIE_rxp_v[2] }]
set_property LOC T6   [get_ports { PCIE_rxp_v[3] }]
set_property LOC V6   [get_ports { PCIE_rxp_v[4] }]
set_property LOC W4   [get_ports { PCIE_rxp_v[5] }]
set_property LOC Y6   [get_ports { PCIE_rxp_v[6] }]
set_property LOC AA4  [get_ports { PCIE_rxp_v[7] }]

set_property LOC M5   [get_ports { PCIE_rxn_v[0] }]
set_property LOC P5   [get_ports { PCIE_rxn_v[1] }]
set_property LOC R3   [get_ports { PCIE_rxn_v[2] }]
set_property LOC T5   [get_ports { PCIE_rxn_v[3] }]
set_property LOC V5   [get_ports { PCIE_rxn_v[4] }]
set_property LOC W3   [get_ports { PCIE_rxn_v[5] }]
set_property LOC Y5   [get_ports { PCIE_rxn_v[6] }]
set_property LOC AA3  [get_ports { PCIE_rxn_v[7] }]

set_property LOC L4   [get_ports { PCIE_txp[0] }]
set_property LOC M2   [get_ports { PCIE_txp[1] }]
set_property LOC N4   [get_ports { PCIE_txp[2] }]
set_property LOC P2   [get_ports { PCIE_txp[3] }]
set_property LOC T2   [get_ports { PCIE_txp[4] }]
set_property LOC U4   [get_ports { PCIE_txp[5] }]
set_property LOC V2   [get_ports { PCIE_txp[6] }]
set_property LOC Y2   [get_ports { PCIE_txp[7] }]

set_property LOC L3   [get_ports { PCIE_txn[0] }]
set_property LOC M1   [get_ports { PCIE_txn[1] }]
set_property LOC N3   [get_ports { PCIE_txn[2] }]
set_property LOC P1   [get_ports { PCIE_txn[3] }]
set_property LOC T1   [get_ports { PCIE_txn[4] }]
set_property LOC U3   [get_ports { PCIE_txn[5] }]
set_property LOC V1   [get_ports { PCIE_txn[6] }]
set_property LOC Y1   [get_ports { PCIE_txn[7] }]

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
set_property LOC IBUFDS_GTE2_X0Y1  [get_cells { *pci_clk_100mhz_buf }]


######################################################################################################
# TIMING CONSTRAINTS
######################################################################################################

# # clocks
create_clock -name bscan_refclk -period 20 [get_pins host_pciehost_bscan_bscan/TCK]
create_clock -name pci_refclk -period 10 [get_pins *pci_clk_100mhz_buf/O]

# ignore this timing violation
set_false_path -from [get_pins host_ep7/pclk_sel_reg/C]
