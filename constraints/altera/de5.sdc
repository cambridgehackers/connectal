
#**************************************************************
# Create Clock
#**************************************************************

create_clock -period 10 [get_ports pcie_refclk_p]
create_clock -period 1.552 [get_ports sfp_refclk]
create_clock -period 20 [get_ports osc_50_b3b]
create_clock -period 20 [get_ports osc_50_b3d]
create_clock -period 20 [get_ports osc_50_b4d]
create_clock -period 20 [get_ports osc_50_b4a]
create_clock -period 20 [get_ports osc_50_b7a]
create_clock -period 20 [get_ports osc_50_b7d]
create_clock -period 20 [get_ports osc_50_b8d]
create_clock -period 20 [get_ports osc_50_b8a]

set_clock_groups -exclusive -group [get_clocks { *central_clk_div0* }] -group [get_clocks { *_hssi_pcie_hip* }]
set_clock_groups -exclusive -group [get_clocks { refclk*clkout }] -group [get_clocks { *div0*coreclkout }]

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks

#**************************************************************
# Set Clock Latency
#**************************************************************


#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************


#Constraining JTAG interface
#TCK port
create_clock -name altera_reserved_tck -period 100 [get_ports altera_reserved_tck]
#cut all paths to and from tck
set_clock_groups -exclusive -group [get_clocks altera_reserved_tck]
#constrain the TDI port
set_input_delay -clock altera_reserved_tck 20 [get_ports altera_reserved_tdi]
#constrain the TMS port
set_input_delay -clock altera_reserved_tck 20 [get_ports altera_reserved_tms]
#constrain the TDO port
set_output_delay -clock altera_reserved_tck 20 [get_ports altera_reserved_tdo]


