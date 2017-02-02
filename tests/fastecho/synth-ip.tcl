source "board.tcl" 
source "$connectaldir/../fpgamake/tcl/ipcore.tcl"

if {[version -short] >= "2016.1"} {
    set dual_clock_axis_fifo_version 13.1
} else {
    set dual_clock_axis_fifo_version 13.0
}

fpgamake_ipcore fifo_generator $dual_clock_axis_fifo_version dual_clock_axis_fifo_32x8 [list \
                           config.interface_type {axi_stream} \
                           config.clock_type_axi {independent_clock} \
                           config.tdata_num_bytes {4} \
                           config.tuser_width {0} \
                           config.enable_tlast {true} \
                           config.has_tkeep {true} \
                           config.fifo_application_type_axis {data_fifo} \
                           config.reset_type {asynchronous_reset} \
                           ]

