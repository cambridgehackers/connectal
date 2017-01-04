set dbgs [get_nets -hierarchical -filter {MARK_DEBUG}]
if {[llength $dbgs] > 0} {
    set_property mark_debug false $dbgs
}

opt_design
place_design
phys_opt_design
route_design
write_bitstream -force debug.bit
write_debug_probes -force debug.ltx
report_timing_summary -file debug_timing_summary.txt
