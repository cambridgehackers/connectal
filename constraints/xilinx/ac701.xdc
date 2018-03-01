######################################################################################################
##  File name :       default.xdc
##
##  Details :     Constraints file
##                    FPGA family:       artix7
##                    FPGA:              xc7a200tfbg676
##                    Speedgrade:        -2
##
######################################################################################################

######################################################################################################
# PIN ASSIGNMENTS
######################################################################################################
set_property LOC M26 [get_ports {GPIO_leds[0]}]
set_property LOC T24 [get_ports {GPIO_leds[1]}]
set_property LOC T25 [get_ports {GPIO_leds[2]}]
set_property LOC R26 [get_ports {GPIO_leds[3]}]
set_property LOC U4 [get_ports {RST_cpu_reset}]

set_property IOSTANDARD LVCMOS33 [get_ports {GPIO_leds[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GPIO_leds[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GPIO_leds[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GPIO_leds[3]}]
set_property IOSTANDARD LVCMOS15 [get_ports {RST_cpu_reset}]

set_property SLEW SLOW [get_ports GPIO_leds]
set_property DRIVE 12 [get_ports GPIO_leds]

set_property LOC F11   [get_ports { CLK_pci_sys_clk_p }]
set_property LOC E11  [get_ports { CLK_pci_sys_clk_n }]
set_property LOC M20  [get_ports { RST_N_pci_sys_reset_n }]

set_property LOC R3 [get_ports { CLK_sys_clk_p }]
set_property LOC P3 [get_ports { CLK_sys_clk_n }]
# set_property LOC M21  [get_ports { CLK_user_clk_p }]
# set_property LOC M22  [get_ports { CLK_user_clk_n }]

set_property LOC D12  [get_ports { PCIE_rxp_i[0] }]
set_property LOC B13  [get_ports { PCIE_rxp_i[1] }]
set_property LOC D14  [get_ports { PCIE_rxp_i[2] }]
set_property LOC B11  [get_ports { PCIE_rxp_i[3] }]

set_property LOC C12  [get_ports { PCIE_rxn_i[0] }]
set_property LOC A13  [get_ports { PCIE_rxn_i[1] }]
set_property LOC C14  [get_ports { PCIE_rxn_i[2] }]
set_property LOC A11  [get_ports { PCIE_rxn_i[3] }]

set_property LOC D10   [get_ports { PCIE_txp[0] }]
set_property LOC B9   [get_ports { PCIE_txp[1] }]
set_property LOC D8   [get_ports { PCIE_txp[2] }]
set_property LOC B7   [get_ports { PCIE_txp[3] }]

set_property LOC C10  [get_ports { PCIE_txn[0] }]
set_property LOC A9   [get_ports { PCIE_txn[1] }]
set_property LOC C8   [get_ports { PCIE_txn[2] }]
set_property LOC A7   [get_ports { PCIE_txn[3] }]

######################################################################################################
# I/O STANDARDS
######################################################################################################
set_property IOSTANDARD LVCMOS33    [get_ports { GPIO_leds[*] }]
set_property IOSTANDARD DIFF_SSTL15 [get_ports { CLK_sys_clk_* }]
# set_property IOSTANDARD DIFF_SSTL15 [get_ports { CLK_user_clk_* }]
set_property IOSTANDARD LVCMOS33    [get_ports { RST_N_pci_sys_reset_n }]
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
set_property LOC IBUFDS_GTE2_X0Y2  [get_cells { *pci_clk_100mhz_buf }]
#set_property LOC MMCME2_ADV_X1Y1 [get_cells -hier -filter { NAME =~ *clk_gen_pll }]

#
# PCI Express Block placement. This constraint selects the PCI Express
# Block to be used.
#
set_property LOC PCIE_X0Y0 [get_cells -hierarchical -regexp {.*pcie_7x_i/pcie_block_i}]
set_property LOC MMCME2_ADV_X0Y4 [get_cells *clkgen_pll]
set_property LOC MMCME2_ADV_X0Y3 [get_cells *_ep/ext_clk.pipe_clock_i/mmcm_i]

#
# BlockRAM placement
#
set_property LOC RAMB36_X1Y46 [get_cells {*\/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[3].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}] */
set_property LOC RAMB36_X1Y45 [get_cells {*\/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[2].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}] */
set_property LOC RAMB36_X1Y44 [get_cells {*\/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[1].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}] */
set_property LOC RAMB36_X1Y43 [get_cells {*\/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[0].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}] */
set_property LOC RAMB36_X1Y42 [get_cells {*\/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[0].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}] */
set_property LOC RAMB36_X1Y41 [get_cells {*\/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[1].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}] */
set_property LOC RAMB36_X1Y40 [get_cells {*\/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[2].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}] */
set_property LOC RAMB36_X1Y39 [get_cells {*\/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[3].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}] */

######################################################################################################
# TIMING CONSTRAINTS
######################################################################################################

## in pcie-clocks.xdc
