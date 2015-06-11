##
if [file exists zc702/Impl/Reconf/top-post-route.dcp] {
    open_checkpoint zc702/Impl/Reconf/top-post-route.dcp
    update_design -cells top/lEcho_bounce -black_box
    lock_design -level routing
    read_checkpoint -cell top/lEcho_bounce zc702/Synth/mkBounce1/mkBounce1-synth.dcp
    opt_design
    place_design
    phys_opt_design
    route_design
    file mkdir zc702/Impl/Reconf
    report_timing_summary -file zc702/Impl/Reconf/reconf-post-route-timing-summary.rpt
    write_checkpoint -force zc702/Impl/Reconf/reconf-post-route.dcp
    write_bitstream -force zc702/Impl/Reconf/reconf.bit
} else {
    open_checkpoint zc702/Synth/mkZynqTop/mkZynqTop-synth.dcp
    read_xdc ../../constraints/xilinx/zc7z020clg484.xdc
    read_xdc floorplan.xdc
    set_property RESET_AFTER_RECONFIG 1 [get_pblocks pblock_lEcho_bounce]
    set_propert HD.RECONFIGURABLE 1 [get_cells top/lEcho_bounce]
    read_checkpoint -cell top/lEcho_bounce zc702/Synth/mkBounce1/mkBounce1-synth.dcp
    opt_design
    place_design
    phys_opt_design
    route_design
    file mkdir zc702/Impl/Reconf
    report_timing_summary -file zc702/Impl/Reconf/top-post-route-timing-summary.rpt
    write_checkpoint -force zc702/Impl/Reconf/top-post-route.dcp
    write_bitstream -force zc702/Impl/Reconf/top.bit
}
