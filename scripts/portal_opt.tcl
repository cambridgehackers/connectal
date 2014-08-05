command opt_design     hw/opt_design.log
write_checkpoint -force $outputDir/top-post-opt.dcp > hw/temp.log

# power_opt_design
command place_design    hw/place_design.log
report_timing_summary -file $outputDir/top-post-place-timing-summary.rpt > hw/temp.log
report_timing -nworst 20 -sort_by slack -path_type summary -slack_lesser_than 0.2 -unique_pins
report_io -file $outputDir/top-post-place-io.rpt > hw/temp.log
write_checkpoint -force $outputDir/top-post-place > hw/temp.log
command phys_opt_design hw/phys_opt_design.log
report_timing_summary -file $outputDir/top-post-phys-opt-timing-summary.rpt > hw/temp.log
report_timing -nworst 20 -sort_by slack -path_type summary -slack_lesser_than 0.2 -unique_pins
write_checkpoint -force $outputDir/top-post-phys-opt > hw/temp.log
#not in 2013.2 report_timing_summary -warn_on_violation -file $outputDir/top-post-place-timing-summary.rpt > hw/temp.log
#
# STEP#4: run router, report actual utilization and timing, write checkpoint design, run drc, write verilog and xdc out
#
command route_design hw/route_design.log
write_checkpoint -force $outputDir/top-post-route > hw/temp.log
#not in 2013.2 report_timing_summary -warn_on_violation
#not in 2013.2 report_timing_summary -warn_on_violation -file $outputDir/top-post-route-timing-summary.rpt > hw/temp.log
report_timing -nworst 20 -sort_by slack -path_type summary -slack_lesser_than 0.2 -unique_pins
puts "****************************************"
puts "If timing report says 'No timing paths found.' then the design met the timing constraints."
puts "If it reported negative slack, then the design did not meet the timing constraints."
puts "****************************************"
report_timing_summary -file $outputDir/top-post-route-timing-summary.rpt > hw/temp.log
report_timing -sort_by group -max_paths 100 -path_type summary -file $outputDir/top-post-route-timing.rpt > hw/temp.log
report_clock_utilization -file $outputDir/top-clock-util.rpt > hw/temp.log
report_utilization -file $outputDir/top-post-route-util.rpt > hw/temp.log
report_datasheet -file $outputDir/top-post-route_datasheet.rpt > hw/temp.log
report_io -file $outputDir/top-post-route-io.rpt > hw/temp.log
#report_power -file $outputDir/top-post-route-power.rpt
#report_drc -file $outputDir/top-post-imp-drc.rpt
#write_verilog -force $outputDir/top-impl_netlist.v
write_xdc -no_fixed_only -force $outputDir/top-impl.xdc > hw/temp.log

## Halt the flow with an error if the timing constraints weren't met
## (thanks to http://xillybus.com/tutorials/vivado-timing-constraints-error for this way to do it)
set minireport [report_timing_summary -no_header -no_detailed_paths -return_string]
if {! [string match -nocase {*timing constraints are met*} $minireport]} {
#    send_msg_id showstopper-0 error "Timing constraints weren't met. Please check your design."
#    return -code error
   puts "Error: Timing constraints weren't met. Please check your design."
}

#
# STEP#5: generate a bitstream
# 
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
report_drc -file $outputDir/top-post-route-drc.rpt > hw/temp.log
write_bitstream -force -bin_file $outputDir/mkTop.bit

close $rfh
close $cfh
close $wfh
