
# NOTE: typical usage would be "vivado -mode tcl -source create_mkPcieTop_batch.tcl" 
#
# STEP#0: define output directory area.
#
set outputDir ./hw
file mkdir $outputDir
#
# STEP#1: setup design sources and constraints
#
read_verilog [ glob {verilog/*.v} ]
read_verilog [ glob verilog/*.v ]
read_verilog [ glob /scratch/jca/git/xbsv/verilog/*.v ]
read_verilog [ glob /scratch/jca/git/xbsv/xilinx/sources/processing_system7/*.v ]
read_xdc {./constraints/design_1_processing_system7_1_0.xdc}
read_xdc {./constraints/zedboard.xdc}

# STEP#2: run synthesis, report utilization and timing estimates, write checkpoint design
#
synth_design -name ztop_1 -top mkZynqTop -part xc7z020clg484-1 -flatten rebuilt

write_checkpoint -force $outputDir/ztop_1_post_synth
#write_verilog -force $outputDir/ztop_1_netlist.v
#report_timing_summary -file $outputDir/ztop_1_post_synth_timing_summary.rpt
#report_power -file $outputDir/ztop_1_post_synth_power.rpt

##set outputDir ./hw
##open_checkpoint $outputDir/ztop_1_post_synth.dcp
#
# STEP#3: run placement and logic optimization, report utilization and timing estimates, write checkpoint design
#
disconnect_net -net [get_nets -of_objects [get_pins CLK_GATE_fclk_clk0_OBUF_inst/I]] -objects CLK_GATE_fclk_clk0_OBUF_inst/I
disconnect_net -net [get_nets -of_objects [get_pins CLK_fclk_clk0_OBUF_inst/I]] -objects ps7_foo/FCLK_CLK0
connect_net -net CLK_axi_clock_IBUF_BUFG -objects ps7_foo/FCLK_CLK0
disconnect_net -net [get_nets -of_objects [get_pins ps7_foo/FCLK_RESET0_N]] -objects ps7_foo/FCLK_RESET0_N
connect_net -net RST_N_axi_reset_IBUF -objects ps7_foo/FCLK_RESET0_N
disconnect_net -net RST_N_axi_reset_IBUF -objects RST_N_axi_reset_IBUF_inst/O
opt_design
# power_opt_design
place_design
phys_opt_design
write_checkpoint -force $outputDir/ztop_1_post_place
report_timing_summary -file $outputDir/ztop_1_post_place_timing_summary.rpt
#
# STEP#4: run router, report actual utilization and timing, write checkpoint design, run drc, write verilog and xdc out
#
route_design
report_timing_summary -file $outputDir/ztop_1_post_route_timing_summary.rpt
report_timing -sort_by group -max_paths 100 -path_type summary -file $outputDir/ztop_1_post_route_timing.rpt
report_clock_utilization -file $outputDir/ztop_1_clock_util.rpt
report_utilization -file $outputDir/ztop_1_post_route_util.rpt
report_power -file $outputDir/ztop_1_post_route_power.rpt
report_drc -file $outputDir/ztop_1_post_imp_drc.rpt
write_verilog -force $outputDir/ztop_1_impl_netlist.v
write_xdc -no_fixed_only -force $outputDir/ztop_1_impl.xdc
#
# STEP#5: generate a bitstream
# 
write_bitstream -force -bin_file $outputDir/ztop_1.bit
