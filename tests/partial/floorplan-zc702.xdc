
create_pblock pblock_lEcho_bounce
add_cells_to_pblock [get_pblocks pblock_lEcho_bounce] [get_cells -quiet [list top/lEcho_bounce]]
resize_pblock [get_pblocks pblock_lEcho_bounce] -add {SLICE_X34Y100:SLICE_X47Y149}
resize_pblock [get_pblocks pblock_lEcho_bounce] -add {DSP48_X2Y40:DSP48_X2Y59}
set_property SNAPPING_MODE ON [get_pblocks pblock_lEcho_bounce]
