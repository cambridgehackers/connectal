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
set_property LOC AM39 [get_ports { GPIO_leds[0] }]
set_property LOC AN39 [get_ports { GPIO_leds[1] }]
set_property LOC AR37 [get_ports { GPIO_leds[2] }]
set_property LOC AT37 [get_ports { GPIO_leds[3] }]
set_property LOC AR35 [get_ports { GPIO_leds[4] }]
set_property LOC AP41 [get_ports { GPIO_leds[5] }]
set_property LOC AP42 [get_ports { GPIO_leds[6] }]
set_property LOC AU39 [get_ports { GPIO_leds[7] }]
set_property LOC AD8  [get_ports { CLK_pci_sys_clk_p }]
set_property LOC AD7  [get_ports { CLK_pci_sys_clk_n }]
set_property LOC AV35 [get_ports { RST_N_pci_sys_reset_n }]
set_property LOC E19  [get_ports { CLK_sys_clk_p }]
set_property LOC E18  [get_ports { CLK_sys_clk_n }]

set_property LOC Y4   [get_ports { PCIE_rxp_v[0] }]
set_property LOC AA6  [get_ports { PCIE_rxp_v[1] }]
set_property LOC AB4  [get_ports { PCIE_rxp_v[2] }]
set_property LOC AC6  [get_ports { PCIE_rxp_v[3] }]
set_property LOC AD4  [get_ports { PCIE_rxp_v[4] }]
set_property LOC AE6  [get_ports { PCIE_rxp_v[5] }]
set_property LOC AF4  [get_ports { PCIE_rxp_v[6] }]
set_property LOC AG6  [get_ports { PCIE_rxp_v[7] }]

set_property LOC Y3   [get_ports { PCIE_rxn_v[0] }]
set_property LOC AA5  [get_ports { PCIE_rxn_v[1] }]
set_property LOC AB3  [get_ports { PCIE_rxn_v[2] }]
set_property LOC AC5  [get_ports { PCIE_rxn_v[3] }]
set_property LOC AD3  [get_ports { PCIE_rxn_v[4] }]
set_property LOC AE5  [get_ports { PCIE_rxn_v[5] }]
set_property LOC AF3  [get_ports { PCIE_rxn_v[6] }]
set_property LOC AG5  [get_ports { PCIE_rxn_v[7] }]

set_property LOC W2   [get_ports { PCIE_txp[0] }]
set_property LOC AA2  [get_ports { PCIE_txp[1] }]
set_property LOC AC2  [get_ports { PCIE_txp[2] }]
set_property LOC AE2  [get_ports { PCIE_txp[3] }]
set_property LOC AG2  [get_ports { PCIE_txp[4] }]
set_property LOC AH4  [get_ports { PCIE_txp[5] }]
set_property LOC AJ2  [get_ports { PCIE_txp[6] }]
set_property LOC AK4  [get_ports { PCIE_txp[7] }]

set_property LOC W1   [get_ports { PCIE_txn[0] }]
set_property LOC AA1  [get_ports { PCIE_txn[1] }]
set_property LOC AC1  [get_ports { PCIE_txn[2] }]
set_property LOC AE1  [get_ports { PCIE_txn[3] }]
set_property LOC AG1  [get_ports { PCIE_txn[4] }]
set_property LOC AH3  [get_ports { PCIE_txn[5] }]
set_property LOC AJ1  [get_ports { PCIE_txn[6] }]
set_property LOC AK3  [get_ports { PCIE_txn[7] }]

######################################################################################################
# I/O STANDARDS
######################################################################################################
set_property IOSTANDARD LVCMOS15    [get_ports { GPIO_leds[*] }]
set_property IOSTANDARD DIFF_SSTL15 [get_ports { CLK_sys_clk_* }]
set_property IOSTANDARD LVCMOS15    [get_ports { RST_N_pci_sys_reset_n }]
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
set_property LOC IBUFDS_GTE2_X1Y5  [get_cells { *pci_clk_100mhz_buf }]

set_property LOC MMCME2_ADV_X1Y2 [get_cells -hier -filter { NAME =~ */ext_clk.pipe_clock_i/mmcm_i }]
set_property LOC MMCME2_ADV_X1Y1 [get_cells -hier -filter { NAME =~ *clkgen_pll }]
set_property LOC MMCME2_ADV_X1Y5 [get_cells -hier -filter { NAME =~ *clk_gen_pll }]

#
# Transceiver instance placement.  This constraint selects the
# transceivers to be used, which also dictates the pinout for the
# transmit and receive differential pairs.  Please refer to the
# Virtex-7 GT Transceiver User Guide (UG) for more information.
#

# PCIe Lane 0
set_property LOC GTXE2_CHANNEL_X1Y11 [get_cells -hierarchical -regexp {.*pipe_lane\[0\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
# PCIe Lane 1
set_property LOC GTXE2_CHANNEL_X1Y10 [get_cells -hierarchical -regexp {.*pipe_lane\[1\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
# PCIe Lane 2
set_property LOC GTXE2_CHANNEL_X1Y9 [get_cells -hierarchical -regexp {.*pipe_lane\[2\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
# PCIe Lane 3
set_property LOC GTXE2_CHANNEL_X1Y8 [get_cells -hierarchical -regexp {.*pipe_lane\[3\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
# PCIe Lane 4
set_property LOC GTXE2_CHANNEL_X1Y7 [get_cells -hierarchical -regexp {.*pipe_lane\[4\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
# PCIe Lane 5
set_property LOC GTXE2_CHANNEL_X1Y6 [get_cells -hierarchical -regexp {.*pipe_lane\[5\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
# PCIe Lane 6
set_property LOC GTXE2_CHANNEL_X1Y5 [get_cells -hierarchical -regexp {.*pipe_lane\[6\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
# PCIe Lane 7
set_property LOC GTXE2_CHANNEL_X1Y4 [get_cells -hierarchical -regexp {.*pipe_lane\[7\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]

#
# PCI Express Block placement. This constraint selects the PCI Express
# Block to be used.
#
set_property LOC PCIE_X1Y0 [get_cells -hierarchical -regexp {.*pcie_7x_i/pcie_block_i}]

#
# BlockRAM placement
#
set_property LOC RAMB36_X14Y25 [get_cells {*/pcie_7x_v2_1_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[7].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X14Y26 [get_cells {*/pcie_7x_v2_1_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[6].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X13Y27 [get_cells {*/pcie_7x_v2_1_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[5].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X13Y26 [get_cells {*/pcie_7x_v2_1_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[4].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X13Y25 [get_cells {*/pcie_7x_v2_1_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[3].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X13Y24 [get_cells {*/pcie_7x_v2_1_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[2].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X13Y23 [get_cells {*/pcie_7x_v2_1_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[1].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X13Y22 [get_cells {*/pcie_7x_v2_1_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[0].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X13Y21 [get_cells {*/pcie_7x_v2_1_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[0].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X13Y20 [get_cells {*/pcie_7x_v2_1_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[1].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X13Y19 [get_cells {*/pcie_7x_v2_1_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[2].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X13Y18 [get_cells {*/pcie_7x_v2_1_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[3].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X13Y17 [get_cells {*/pcie_7x_v2_1_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[4].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X14Y17 [get_cells {*/pcie_7x_v2_1_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[5].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X14Y18 [get_cells {*/pcie_7x_v2_1_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[6].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X14Y19 [get_cells {*/pcie_7x_v2_1_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[7].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]

######################################################################################################
# AREA GROUPS
######################################################################################################
#startgroup
#create_pblock pblock_pcie0
#resize_pblock pblock_pcie0 -add { SLICE_X174Y51:SLICE_X221Y149 DSP48_X17Y22:DSP48_X19Y59 RAMB18_X11Y22:RAMB18_X14Y59 RAMB36_X11Y11:RAMB36_X14Y29 }
#add_cells_to_pblock pblock_pcie0 [get_cells [list *_pcie_ep*]]
#add_cells_to_pblock pblock_pcie0 [get_cells [list *_outFifo*]]
#add_cells_to_pblock pblock_pcie0 [get_cells [list *_inFifo*]]
#add_cells_to_pblock pblock_pcie0 [get_cells [list *_fifoTxData_*]]
#add_cells_to_pblock pblock_pcie0 [get_cells [list *_fifoRxData_*]]
#add_cells_to_pblock pblock_pcie0 [get_cells */pbb*]
#add_cells_to_pblock pblock_pcie0 [get_cells [list *fS1OutPort*]]
#add_cells_to_pblock pblock_pcie0 [get_cells [list *fS1MsgOut*]]
#add_cells_to_pblock pblock_pcie0 [get_cells [list *fS2MsgOut*]]
#endgroup




######################################################################################################
# TIMING CONSTRAINTS
######################################################################################################
 
create_clock -name bscan_refclk -period 20 [get_pins host_pciehost_bscan_bscan/TCK]
create_clock -name pci_refclk -period 10 [get_pins *pci_clk_100mhz_buf/O]

## no longer needed?
create_clock -name pci_extclk -period 10 [get_pins *ep7/pcie_ep/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i/TXOUTCLK]
set_clock_groups -name ___clk_groups_generated_0_1_0_0_0 -physically_exclusive -group [get_clocks clk_125mhz] -group [get_clocks clk_250mhz]
