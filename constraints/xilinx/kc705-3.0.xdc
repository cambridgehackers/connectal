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
set_property LOC AB8  [get_ports { GPIO_leds[0] }]
set_property LOC AA8  [get_ports { GPIO_leds[1] }]
set_property LOC AC9  [get_ports { GPIO_leds[2] }]
set_property LOC AB9  [get_ports { GPIO_leds[3] }]
set_property LOC AE26 [get_ports { GPIO_leds[4] }]
set_property LOC G19  [get_ports { GPIO_leds[5] }]
set_property LOC E18  [get_ports { GPIO_leds[6] }]
set_property LOC F16  [get_ports { GPIO_leds[7] }]

# set_property LOC Y28  [get_ports { DIP_3_gpio }]
# set_property LOC AA28 [get_ports { DIP_2_gpio }]
# set_property LOC W29  [get_ports { DIP_1_gpio }]
# set_property LOC Y29  [get_ports { DIP_0_gpio }]

#set_property LOC G12  [get_ports { BUTTON_0_gpio }]
#set_property LOC AC6  [get_ports { BUTTON_1_gpio }]
#set_property LOC AB12 [get_ports { BUTTON_2_gpio }]
#set_property LOC AG5  [get_ports { BUTTON_3_gpio }]
#set_property LOC AA12 [get_ports { BUTTON_4_gpio }]

# set_property LOC AA21 [get_ports { BUTTON_0_gpio }]
# set_property LOC AB22 [get_ports { BUTTON_1_gpio }]
# set_property LOC AB23 [get_ports { BUTTON_2_gpio }]
# set_property LOC AA22 [get_ports { BUTTON_3_gpio }]
# set_property LOC AA23 [get_ports { BUTTON_4_gpio }]


# set_property LOC Y10  [get_ports { LCD_db[3] }]
# set_property LOC AA11 [get_ports { LCD_db[2] }]
# set_property LOC AA10 [get_ports { LCD_db[1] }]
# set_property LOC AA13 [get_ports { LCD_db[0] }]
# set_property LOC AB10 [get_ports { LCD_e }]
# set_property LOC Y11  [get_ports { LCD_rs }]
# set_property LOC AB13 [get_ports { LCD_rw }]

set_property LOC U8   [get_ports { CLK_pci_sys_clk_p }]
set_property LOC U7   [get_ports { CLK_pci_sys_clk_n }]
set_property LOC G25  [get_ports { RST_N_pci_sys_reset_n }]
set_property LOC AD12 [get_ports { CLK_sys_clk_p }]
set_property LOC AD11 [get_ports { CLK_sys_clk_n }]
set_property LOC K28  [get_ports { CLK_user_clk_p }]
set_property LOC K29  [get_ports { CLK_user_clk_n }]

set_property LOC M6   [get_ports { PCIE_rxp_i[0] }]
set_property LOC P6   [get_ports { PCIE_rxp_i[1] }]
set_property LOC R4   [get_ports { PCIE_rxp_i[2] }]
set_property LOC T6   [get_ports { PCIE_rxp_i[3] }]
set_property LOC V6   [get_ports { PCIE_rxp_i[4] }]
set_property LOC W4   [get_ports { PCIE_rxp_i[5] }]
set_property LOC Y6   [get_ports { PCIE_rxp_i[6] }]
set_property LOC AA4  [get_ports { PCIE_rxp_i[7] }]

set_property LOC M5   [get_ports { PCIE_rxn_i[0] }]
set_property LOC P5   [get_ports { PCIE_rxn_i[1] }]
set_property LOC R3   [get_ports { PCIE_rxn_i[2] }]
set_property LOC T5   [get_ports { PCIE_rxn_i[3] }]
set_property LOC V5   [get_ports { PCIE_rxn_i[4] }]
set_property LOC W3   [get_ports { PCIE_rxn_i[5] }]
set_property LOC Y5   [get_ports { PCIE_rxn_i[6] }]
set_property LOC AA3  [get_ports { PCIE_rxn_i[7] }]

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
set_property IOSTANDARD LVCMOS15    [get_ports { GPIO_leds[*] }]
# set_property IOSTANDARD LVCMOS15    [get_ports { DIP_*_gpio }]
# set_property IOSTANDARD LVCMOS25    [get_ports { BUTTON_*_gpio }]
# set_property IOSTANDARD LVCMOS15    [get_ports { LCD_* }]
set_property IOSTANDARD DIFF_SSTL15 [get_ports { CLK_sys_clk_* }]
set_property IOSTANDARD DIFF_SSTL15 [get_ports { CLK_user_clk_* }]
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
set_property LOC MMCME2_ADV_X1Y1 [get_cells -hier -filter { NAME =~ *clk_gen_pll }]

#
# Transceiver instance placement.  This constraint selects the
# transceivers to be used, which also dictates the pinout for the
# transmit and receive differential pairs.  Please refer to the
# Virtex-7 GT Transceiver User Guide (UG) for more information.
#

# PCIe Lane 0
set_property LOC GTXE2_CHANNEL_X0Y7 [get_cells -hierarchical -regexp {.*pipe_lane\[0\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
# PCIe Lane 1
set_property LOC GTXE2_CHANNEL_X0Y6 [get_cells -hierarchical -regexp {.*pipe_lane\[1\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
# PCIe Lane 2
set_property LOC GTXE2_CHANNEL_X0Y5 [get_cells -hierarchical -regexp {.*pipe_lane\[2\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
# PCIe Lane 3
set_property LOC GTXE2_CHANNEL_X0Y4 [get_cells -hierarchical -regexp {.*pipe_lane\[3\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
# PCIe Lane 4
set_property LOC GTXE2_CHANNEL_X0Y3 [get_cells -hierarchical -regexp {.*pipe_lane\[4\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
# PCIe Lane 5
set_property LOC GTXE2_CHANNEL_X0Y2 [get_cells -hierarchical -regexp {.*pipe_lane\[5\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
# PCIe Lane 6
set_property LOC GTXE2_CHANNEL_X0Y1 [get_cells -hierarchical -regexp {.*pipe_lane\[6\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
# PCIe Lane 7
set_property LOC GTXE2_CHANNEL_X0Y0 [get_cells -hierarchical -regexp {.*pipe_lane\[7\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]

#
# PCI Express Block placement. This constraint selects the PCI Express
# Block to be used.
#
set_property LOC PCIE_X0Y0 [get_cells -hierarchical -regexp {.*pcie_7x_i/pcie_block_i}]

#
# BlockRAM placement
#
set_property LOC RAMB36_X4Y35 [get_cells {*/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[3].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X4Y34 [get_cells {*/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[2].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X4Y33 [get_cells {*/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[1].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X4Y32 [get_cells {*/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[0].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X4Y31 [get_cells {*/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[0].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X4Y30 [get_cells {*/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[1].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X4Y29 [get_cells {*/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[2].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
set_property LOC RAMB36_X4Y28 [get_cells {*/pcie_7x_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[3].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]

######################################################################################################
# AREA GROUPS
######################################################################################################
## startgroup
## create_pblock pblock_pcie0
## resize_pblock pblock_pcie0 -add {SLICE_X70Y139:SLICE_X147Y299 DSP48_X3Y56:DSP48_X5Y119 RAMB18_X3Y56:RAMB18_X6Y119 RAMB36_X3Y28:RAMB36_X6Y59}
## add_cells_to_pblock pblock_pcie0 [get_cells [list *_pcie_*]]
## add_cells_to_pblock pblock_pcie0 [get_cells [list *_outFifo*]]
## add_cells_to_pblock pblock_pcie0 [get_cells [list *_inFifo*]]
## add_cells_to_pblock pblock_pcie0 [get_cells [list *_fifoTxData_*]]
## add_cells_to_pblock pblock_pcie0 [get_cells [list *_fifoRxData_*]]
## add_cells_to_pblock pblock_pcie0 [get_cells [list *\/pbb*]]
## add_cells_to_pblock pblock_pcie0 [get_cells [list *fS1OutPort*]]
## add_cells_to_pblock pblock_pcie0 [get_cells [list *fS1MsgOut*]]
## add_cells_to_pblock pblock_pcie0 [get_cells [list *fS2MsgOut*]]
## endgroup


######################################################################################################
# TIMING CONSTRAINTS
######################################################################################################

# # clocks
create_clock -name bscan_refclk -period 20 [get_pins -hier -filter {NAME=~"*pcieBscanBram_bscan/TCK"}]

create_clock -name pci_refclk -period 10 [get_pins *pci_clk_100mhz_buf/O]
create_clock -name sys_clk -period 5 [get_pins *sys_clk_200mhz/O]

create_clock -name pci_extclk -period 10 [get_pins *ep7/pcie_ep/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i/TXOUTCLK]

# # False Paths
# set_false_path -from [get_ports { RST_N_pci_sys_reset_n }]
set_false_path -through [get_pins -hierarchical {*pcie_block_i/PLPHYLNKUPN*}]
set_false_path -through [get_pins -hierarchical {*pcie_block_i/PLRECEIVEDHOTRST*}]

#set_false_path -through [get_nets {*/pcie_7x_i/inst/inst/gt_top_i/pipe_wrapper_i/user_resetdone*}]
set_false_path -through [get_nets {*/pcie_7x_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].pipe_rate.pipe_rate_i/*}]
set_false_path -through [get_nets {*/pcie_7x_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].pipe_rate.pipe_rate_i/*}]
set_false_path -through [get_nets {*/pcie_7x_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].pipe_rate.pipe_rate_i/*}]
set_false_path -through [get_nets {*/pcie_7x_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].pipe_rate.pipe_rate_i/*}]
set_false_path -through [get_nets {*/pcie_7x_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[4].pipe_rate.pipe_rate_i/*}]
set_false_path -through [get_nets {*/pcie_7x_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[5].pipe_rate.pipe_rate_i/*}]
set_false_path -through [get_nets {*/pcie_7x_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[6].pipe_rate.pipe_rate_i/*}]
set_false_path -through [get_nets {*/pcie_7x_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[7].pipe_rate.pipe_rate_i/*}]

set_false_path -through [get_cells {*/pcie_7x_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_reset.pipe_reset_i/cpllreset_reg*}]

set_false_path -through [get_nets {*/ext_clk.pipe_clock_i/pclk_sel*}]

set_case_analysis 1 [get_pins {*/ext_clk.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S0}] 
set_case_analysis 0 [get_pins {*/ext_clk.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1}] 

set_clock_groups -name ___clk_groups_generated_0_1_0_0_0 -physically_exclusive -group [get_clocks clk_125mhz] -group [get_clocks clk_250mhz]

set_clock_groups -name async_sysclk_coreclk -asynchronous -group [get_clocks -include_generated_clocks sys_clk] -group [get_clocks -include_generated_clocks user_clk] -group [get_clocks -include_generated_clocks pci_refclk]

set_max_delay -from [get_clocks noc_clk] -to [get_clocks clk_userclk2] 8.000 -datapath_only
set_max_delay -from [get_clocks clk_userclk2] -to [get_clocks noc_clk] 8.000 -datapath_only
set_max_delay -from [get_clocks cclock] -to [get_clocks core_clock] 20.000 -datapath_only
set_max_delay -from [get_clocks uclock] -to [get_clocks core_clock] 20.000 -datapath_only
set_max_delay -from [get_clocks core_clock] -to [get_clocks cclock] 20.000 -datapath_only
set_max_delay -from [get_clocks core_clock] -to [get_clocks uclock] 20.000 -datapath_only
