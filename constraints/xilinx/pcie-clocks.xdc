#create_clock -name bscan_refclk -period 20 [get_pins host_pciehost_bscan_bscan/TCK]
create_clock -name pci_refclk -period 10 [get_ports CLK_pci_sys_clk_p]
create_clock -name sys_clk -period 5 [get_ports CLK_sys_clk_p]
    
create_clock -name sys_clk1_300 -period 3.333 [get_ports CLK_sys_clk1_300_p]
create_clock -name sys_clk2_300 -period 3.333 [get_ports CLK_sys_clk2_300_p]

create_clock -name sys_clk_300 -period 3.333 [get_ports CLK_sys_clk_300_p]
create_clock -name sys_clk1_250 -period 4.0 [get_ports CLK_sys_clk1_250_p]
create_clock -name sys_clk2_250 -period 4.0 [get_ports CLK_sys_clk2_250_p]




set_max_delay -from [get_clocks {clkgen_pll_CLKOUT0}] -to   [get_clocks {userclk2}] [get_property PERIOD [get_clocks {userclk2}]] -datapath_only
set_max_delay -to   [get_clocks {clkgen_pll_CLKOUT0}] -from [get_clocks {userclk2}] [get_property PERIOD [get_clocks {userclk2}]]           -datapath_only

set_max_delay -from [get_clocks {clkgen_pll_CLKOUT1}] -to   [get_clocks {userclk2}] [get_property PERIOD [get_clocks {userclk2}]] -datapath_only
set_max_delay -to   [get_clocks {clkgen_pll_CLKOUT1}] -from [get_clocks {userclk2}] [get_property PERIOD [get_clocks {userclk2}]]           -datapath_only

set_max_delay -from [get_clocks {clkgen_pll_CLKOUT2}] -to   [get_clocks {userclk2}] [get_property PERIOD [get_clocks {userclk2}]] -datapath_only
set_max_delay -to   [get_clocks {clkgen_pll_CLKOUT2}] -from [get_clocks {userclk2}] [get_property PERIOD [get_clocks {userclk2}]]           -datapath_only

set_max_delay -from [get_clocks {userclk2}] -to   [get_clocks {sys_clk}] 4.0 -datapath_only
set_max_delay -to   [get_clocks {userclk2}] -from [get_clocks {sys_clk}] 4.0 -datapath_only

set_max_delay -from [get_clocks {userclk2}] -to   [get_clocks {clk_pll_i}] 4.0 -datapath_only
set_max_delay -to   [get_clocks {userclk2}] -from [get_clocks {clk_pll_i}] 4.0 -datapath_only
