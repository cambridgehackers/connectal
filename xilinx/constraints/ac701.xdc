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
set_property LOC M26 [get_ports {leds[0]}]
set_property LOC T24 [get_ports {leds[1]}]
set_property LOC T25 [get_ports {leds[2]}]
set_property LOC R26 [get_ports {leds[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {leds[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[3]}]

set_property SLEW SLOW [get_ports leds]
set_property DRIVE 12 [get_ports leds]

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
set_property IOSTANDARD LVCMOS33    [get_ports { leds[*] }]
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
set_property LOC IBUFDS_GTE2_X0Y2  [get_cells { *x7pcie_pci_clk_100mhz_buf }]
#set_property LOC MMCME2_ADV_X1Y1 [get_cells -hier -filter { NAME =~ *clk_gen_pll }]

#
# PCI Express Block placement. This constraint selects the PCI Express
# Block to be used.
#
set_property LOC PCIE_X0Y0 [get_cells -hierarchical -regexp {.*pcie_7x_i/pcie_block_i}]
set_property LOC MMCME2_ADV_X0Y4 [get_cells top_x7pcie_clkgen_pll]
set_property LOC MMCME2_ADV_X0Y3 [get_cells top_x7pcie_pcie_ep/ext_clk.pipe_clock_i/mmcm_i]

#
# BlockRAM placement
#
## set_property LOC RAMB36_X4Y35 [get_cells {*\/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[3].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}] */
## set_property LOC RAMB36_X4Y34 [get_cells {*\/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[2].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}] */
## set_property LOC RAMB36_X4Y33 [get_cells {*\/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[1].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}] */
## set_property LOC RAMB36_X4Y32 [get_cells {*\/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[0].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}] */
## set_property LOC RAMB36_X4Y31 [get_cells {*\/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[0].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}] */
## set_property LOC RAMB36_X4Y30 [get_cells {*\/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[1].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}] */
## set_property LOC RAMB36_X4Y29 [get_cells {*\/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[2].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}] */
## set_property LOC RAMB36_X4Y28 [get_cells {*\/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[3].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}] */

######################################################################################################
# TIMING CONSTRAINTS
######################################################################################################

# # clocks
create_clock -name pci_refclk -period 10 [get_pins *x7pcie_pci_clk_100mhz_buf/O]
create_clock -name sys_clk -period 5 [get_pins *x7pcie_sys_clk_200mhz/O]

create_clock -name pci_extclk -period 10 [get_pins *x7pcie_pcie_ep/pcie_7x_v2_1_i/gt_top_i/PIPE_TXOUTCLK_OUT]

# # False Paths
# set_false_path -from [get_ports { RST_N_pci_sys_reset_n }]
set_false_path -through [get_pins -hierarchical {*pcie_block_i/PLPHYLNKUPN*}]
set_false_path -through [get_pins -hierarchical {*pcie_block_i/PLRECEIVEDHOTRST*}]

set_false_path -through [get_nets {*/ext_clk.pipe_clock_i/pclk_sel*}]

set_case_analysis 1 [get_pins {*/ext_clk.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S0}] 
set_case_analysis 0 [get_pins {*/ext_clk.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1}] 

set_clock_groups -name ___clk_groups_generated_0_1_0_0_0 -physically_exclusive -group [get_clocks clk_125mhz] -group [get_clocks clk_250mhz]

