
# NOTE: typical usage would be "vivado -mode tcl -source create_mkPcieTop_batch.tcl" 
#
# STEP#0: define output directory area.
#
set outputDir ./hw
file mkdir $outputDir

if [file exists {board.tcl}] {
    source {board.tcl}
} else {
    set boardname vc707
    set partname {xc7vx485tffg1761-2}
}

if [file exists $outputDir/mkpcietop_static_routed.dcp] {
    read_checkpoint $outputDir/mkpcietop_static_routed.dcp
    lock_design -level routing
} else {
    read_checkpoint $outputDir/mkpcietop_post_synth.dcp
    read_xdc constraints/$boardname.xdc
}
#start_gui

#
# STEP#3: run placement and logic optimization, report utilization and timing estimates, write checkpoint design
#

read_checkpoint -cell top_portalTop hw/portaltop_post_synth.dcp
if [file exists $outputDir/mkpcietop_static_routed.dcp] {
} else {
    read_xdc $connectaldir/xilinx/constraints/$boardname-portal-pblock.xdc
    set_property HD.RECONFIGURABLE TRUE [get_cells top_portalTop]
    ## if the pblock is aligned to a reconfigurable frame, can use the following
    #set_property RESET_AFTER_RECONFIG true [get_pblocks top_portalTop]
}

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
if [file exists $outputDir/mkpcietop_static_routed.dcp] {
    pr_verify $outputDir/mkpcietop_static_routed.dcp $outputDir/mkpcietop_post_route.dcp
} else {
    update_design -cells [get_cells top_portalTop] -black_box
    write_checkpoint -force $outputDir/mkpcietop_static_routed.dcp
}

