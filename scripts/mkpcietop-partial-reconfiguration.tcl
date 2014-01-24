
# NOTE: typical usage would be "vivado -mode tcl -source create_mkPcieTop_batch.tcl" 
#
# STEP#0: define output directory area.
#
set outputDir ./hw
file mkdir $outputDir

read_checkpoint $outputDir/mkpcietop_post_synth.dcp
read_xdc {./constraints/vc707.xdc}
start_gui

#
# STEP#3: run placement and logic optimization, report utilization and timing estimates, write checkpoint design
#

read_checkpoint -cell portalTop hw/portaltop_post_synth.dcp
startgroup
create_pblock pblock_portalTop
resize_pblock pblock_portalTop -add {SLICE_X0Y0:SLICE_X105Y199 DSP48_X0Y0:DSP48_X8Y79 PCIE_X0Y0:PCIE_X0Y0 RAMB18_X0Y0:RAMB18_X6Y79 RAMB36_X0Y0:RAMB36_X6Y39}
add_cells_to_pblock pblock_portalTop [get_cells portalTop]
endgroup

set_property HD.RECONFIGURABLE TRUE [get_cells portalTop]

delete_pblock pblock_pcie0
startgroup
create_pblock pblock_pcie0
resize_pblock pblock_pcie0 -add {SLICE_X116Y51:SLICE_X221Y149 DSP48_X10Y22:DSP48_X19Y59 RAMB18_X7Y22:RAMB18_X14Y59 RAMB36_X7Y11:RAMB36_X14Y29}
add_cells_to_pblock pblock_pcie0 [get_cells top/x7pcie_pcie_ep]
endgroup

opt_design
# power_opt_design
place_design
#phys_opt_design
write_checkpoint -force $outputDir/mkpcietop_post_place.dcp
report_timing_summary -file $outputDir/mkpcietop_post_place_timing_summary.rpt


#
# STEP#4: run router, report actual utilization and timing, write checkpoint design, run drc, write verilog and xdc out
#
route_design
write_checkpoint -force $outputDir/mkpcietop_post_route.dcp
report_timing_summary -file $outputDir/mkpcietop_post_route_timing_summary.rpt
report_timing -sort_by group -max_paths 100 -path_type summary -file $outputDir/mkpcietop_post_route_timing.rpt
report_clock_utilization -file $outputDir/mkpcietop_clock_util.rpt
report_utilization -file $outputDir/mkpcietop_post_route_util.rpt
#report_power -file $outputDir/mkpcietop_post_route_power.rpt
report_drc -file $outputDir/mkpcietop_post_imp_drc.rpt
#write_verilog -force $outputDir/mkpcietop_impl_netlist.v
write_xdc -no_fixed_only -force $outputDir/mkpcietop_post_route.xdc
#
# STEP#5: generate a bitstream
# 
write_bitstream -force -bin_file $outputDir/mkPcieTop.bit
