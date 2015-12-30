#create_clock -name bscan_refclk -period 20 [get_pins host_pciehost_bscan_bscan/TCK]
create_clock -name pci_refclk -period 10 [get_ports CLK_pci_sys_clk_p]
create_clock -name sys_clk -period 5 [get_ports CLK_sys_clk_p]

set_false_path -from [get_clocks {clkgen_pll_CLKOUT1}] -to   [get_clocks {userclk2}]
set_false_path -to   [get_clocks {clkgen_pll_CLKOUT1}] -from [get_clocks {userclk2}]
set_max_delay -from [get_clocks {clkgen_pll_CLKOUT1}] -to   [get_clocks {userclk2}] [get_property PERIOD [get_clocks {clkgen_pll_CLKOUT1}]] -datapath_only
set_max_delay -to   [get_clocks {clkgen_pll_CLKOUT1}] -from [get_clocks {userclk2}] [get_property PERIOD [get_clocks {userclk2}]]           -datapath_only

set_false_path -from [get_clocks {clkgen_pll_CLKOUT1}] -to   [get_clocks {clkgen_pll_CLKOUT2}]
set_false_path -to   [get_clocks {clkgen_pll_CLKOUT1}] -from [get_clocks {clkgen_pll_CLKOUT2}]

set_false_path -from [get_clocks {clk_125mhz_mux_x1y0}] -to   [get_clocks {userclk2}]
set_false_path -to   [get_clocks {clk_125mhz_mux_x1y0}] -from [get_clocks {userclk2}]

set_false_path -from [get_clocks {clk_250mhz_mux_x1y0}] -to   [get_clocks {userclk2}]
set_false_path -to   [get_clocks {clk_250mhz_mux_x1y0}] -from [get_clocks {userclk2}]

set_false_path -from [get_clocks {clk_pll_i}] -to   [get_clocks {userclk2}]
set_false_path -to   [get_clocks {clk_pll_i}] -from [get_clocks {userclk2}]

set_false_path -from [get_clocks {sys_clk}] -to   [get_clocks {userclk2}]
set_false_path -to   [get_clocks {sys_clk}] -from [get_clocks {userclk2}]
