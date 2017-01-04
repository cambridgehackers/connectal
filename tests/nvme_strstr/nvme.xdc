create_clock -name root_pci_refclk -period 10 [get_ports pcie_refclk_p]

set_max_delay -from [get_clocks {userclk2}] -to   [get_clocks {userclk1}] 4.0 -datapath_only
set_max_delay -to   [get_clocks {userclk2}] -from [get_clocks {userclk1}] 4.0 -datapath_only

set_max_delay -from [get_clocks {userclk2}] -to   [get_clocks {clk_125mhz_mux_*}] 4.0 -datapath_only
set_max_delay -to   [get_clocks {userclk2}] -from [get_clocks {clk_125mhz_mux_*}] 4.0 -datapath_only

set_max_delay -from [get_clocks {userclk2}] -to   [get_clocks {clk_250mhz_mux_*}] 4.0 -datapath_only
set_max_delay -to   [get_clocks {userclk2}] -from [get_clocks {clk_250mhz_mux_*}] 4.0 -datapath_only
