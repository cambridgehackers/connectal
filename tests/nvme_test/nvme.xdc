create_clock -name root_pci_refclk -period 10 [get_ports pcie_refclk_p]

set_max_delay -from [get_clocks {userclk2}] -to   [get_clocks {userclk1}] 4.0 -datapath_only
set_max_delay -to   [get_clocks {userclk2}] -from [get_clocks {userclk1}] 4.0 -datapath_only

set_max_delay -from [get_clocks {userclk2}] -to   [get_clocks {userclk2_1}] 4.0 -datapath_only
set_max_delay -to   [get_clocks {userclk2}] -from [get_clocks {userclk2_1}] 4.0 -datapath_only

set_max_delay -from [get_clocks {userclk2}] -to   [get_clocks {clk_125mhz_mux_*}] 4.0 -datapath_only
set_max_delay -to   [get_clocks {userclk2}] -from [get_clocks {clk_125mhz_mux_*}] 4.0 -datapath_only

set_max_delay -from [get_clocks {userclk2}] -to   [get_clocks {clk_250mhz_mux_*}] 4.0 -datapath_only
set_max_delay -to   [get_clocks {userclk2}] -from [get_clocks {clk_250mhz_mux_*}] 4.0 -datapath_only

set_property LOC GTHE2_CHANNEL_X1Y7 [get_cells {tile_0/*axiRootPort/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gth_channel.gthe2_channel_i}]
# PCIe Lane 1
set_property LOC GTHE2_CHANNEL_X1Y6 [get_cells {tile_0/*axiRootPort/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gth_channel.gthe2_channel_i}]
# PCIe Lane 2
set_property LOC GTHE2_CHANNEL_X1Y5 [get_cells {tile_0/*axiRootPort/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gth_channel.gthe2_channel_i}]
# PCIe Lane 3
set_property LOC GTHE2_CHANNEL_X1Y4 [get_cells {tile_0/*axiRootPort/inst/pcie3_ip_i/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gth_channel.gthe2_channel_i}]
