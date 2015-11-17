
set_false_path -from [get_clocks {clkgen_pll_CLKOUT1}] -to   [get_clocks {userclk2]
set_false_path -to   [get_clocks {clkgen_pll_CLKOUT1}] -from [get_clocks {userclk2]

set_false_path -from [get_clocks {clkgen_pll_CLKOUT1}] -to   [get_clocks {clkgen_pll_CLKOUT2}]
set_false_path -to   [get_clocks {clkgen_pll_CLKOUT1}] -from [get_clocks {clkgen_pll_CLKOUT2}]

set_false_path -from [get_clocks {clk_125mhz_mux_x1y0}] -to   [get_clocks {userclk2]
set_false_path -to   [get_clocks {clk_125mhz_mux_x1y0}] -from [get_clocks {userclk2]

set_false_path -from [get_clocks {clk_250mhz_mux_x1y0}] -to   [get_clocks {userclk2]
set_false_path -to   [get_clocks {clk_250mhz_mux_x1y0}] -from [get_clocks {userclk2]

set_false_path -from [get_clocks {clk_pll_i}] -to   [get_clocks {userclk2]
set_false_path -to   [get_clocks {clk_pll_i}] -from [get_clocks {userclk2]

set_false_path -from [get_clocks {sys_clk}] -to   [get_clocks {userclk2]
set_false_path -to   [get_clocks {sys_clk}] -from [get_clocks {userclk2]

set_false_path -from [get_clocks {clkgen_pll$CLKOUT1}] -to   [get_clocks {userclk2}]
set_false_path -to   [get_clocks {clkgen_pll$CLKOUT1}] -from [get_clocks {userclk2}]

set_false_path -from [get_clocks {clkgen_pll$CLKOUT1}] -to   [get_clocks {clkgen_pll$CLKOUT2}]
set_false_path -to   [get_clocks {clkgen_pll$CLKOUT1}] -from [get_clocks {clkgen_pll$CLKOUT2}]
