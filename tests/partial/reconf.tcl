##
if [file exists zc702/Impl/Reconf/top-post-route.dcp] {
    open_checkpoint zc702/Impl/Reconf/top-post-route.dcp
    update_design -cells */ipDriver -black_box
    lock_design -level routing
    read_checkpoint -cell */ipDriver zc702/Synth/mkBounce1/mkBounce1-synth.dcp
    opt_design
    place_design
    phys_opt_design
    route_design
    file mkdir zc702/Impl/Reconf
    report_timing_summary -file zc702/Impl/Reconf/reconf-post-route-timing-summary.rpt
    write_checkpoint -force zc702/Impl/Reconf/reconf-post-route.dcp
    write_bitstream -force zc702/Impl/Reconf/reconf.bit
} else {
    open_checkpoint zc702/Impl/TopDown/top-post-link.dcp
    update_design -cells */ipDriver -black_box
    read_xdc floorplan.xdc
    set_property RESET_AFTER_RECONFIG 1 [get_pblocks pblock_ipDriver]
    set_propert HD.RECONFIGURABLE 1 [get_cells */ipDriver]
    read_checkpoint -cell */ipDriver zc702/Synth/mkBounce1/mkBounce1-synth.dcp
    opt_design
    place_design
    phys_opt_design
    route_design
    file mkdir zc702/Impl/Reconf
    report_timing_summary -file zc702/Impl/Reconf/top-post-route-timing-summary.rpt
    write_checkpoint -force zc702/Impl/Reconf/top-post-route.dcp
    write_bitstream -force zc702/Impl/Reconf/top.bit
}
