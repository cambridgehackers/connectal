
source $xbsvdir/scripts/xbsv-synth-ip.tcl

if [file exists ../synth-ip.tcl] {
    source ../synth-ip.tcl
}

# STEP#2: run synthesis, report utilization and timing estimates, write checkpoint design
#
command "synth_design -name $xbsv_dut -top $xbsv_dut -part $partname -flatten rebuilt" hw/synth_design.log

write_checkpoint -force $outputDir/top-post-synth > hw/temp.log
#not in 2013.2 report_timing_summary -warn_on_violation
#not in 2013.2 report_timing_summary -warn_on_violation -verbose  -file $outputDir/top-post-synth-timing-summary.rpt > hw/temp.log
report_timing -nworst 20 -sort_by slack -path_type summary -slack_lesser_than 0.2 -unique_pins
report_io -file $outputDir/top-post-synth-io.rpt > hw/temp.log
puts "****************************************"
puts "If timing report says 'No timing paths found.' then the design met the timing constraints."
puts "If it reported negative slack, then the design did not meet the timing constraints."
puts "****************************************"
report_timing_summary -verbose  -file $outputDir/top-post-synth-timing-summary.rpt > hw/temp.log
report_timing -sort_by group -max_paths 100 -path_type summary -file $outputDir/top-post-synth-timing.rpt > hw/temp.log
report_utilization -verbose -file $outputDir/top-post-synth-utilization.txt > hw/temp.log
report_datasheet -file $outputDir/top-post-synth_datasheet.txt > hw/temp.log
write_verilog -force $outputDir/top-netlist.v > hw/temp.log
#report_power -file $outputDir/top-post-synth-power.rpt

#
# STEP#3: run placement and logic optimization, report utilization and timing estimates, write checkpoint design
#
