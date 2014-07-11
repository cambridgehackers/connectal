create_pblock mmtile_0
resize_pblock [get_pblocks mmtile_0] -add {SLICE_X56Y154:SLICE_X163Y274}
resize_pblock [get_pblocks mmtile_0] -add {DSP48_X4Y62:DSP48_X6Y109}
resize_pblock [get_pblocks mmtile_0] -add {RAMB18_X4Y62:RAMB18_X7Y109}
resize_pblock [get_pblocks mmtile_0] -add {RAMB36_X4Y31:RAMB36_X7Y54}
add_cells_to_pblock mmtile_0 [get_cells [list top_mm_dmaMMF_dmaMMF_mmTiles_0]] -clear_locs
set_property CONTAIN_ROUTING true [get_pblocks mmtile_0]
set_property HD.PARTPIN_RANGE {SLICE_X56Y154:SLICE_X60Y274} [get_pins top_mm_dmaMMF_dmaMMF_mmTiles_0/*]

create_pblock mmtile_1
resize_pblock [get_pblocks mmtile_1] -add {SLICE_X56Y6:SLICE_X159Y151}
resize_pblock [get_pblocks mmtile_1] -add {DSP48_X4Y4:DSP48_X6Y59}
resize_pblock [get_pblocks mmtile_1] -add {RAMB18_X4Y4:RAMB18_X7Y59}
resize_pblock [get_pblocks mmtile_1] -add {RAMB36_X4Y2:RAMB36_X7Y29}
add_cells_to_pblock mmtile_1 [get_cells [list top_mm_dmaMMF_dmaMMF_mmTiles_1]] -clear_locs
set_property CONTAIN_ROUTING true [get_pblocks mmtile_1]
set_property HD.PARTPIN_RANGE {SLICE_X56Y6:SLICE_X60Y151} [get_pins top_mm_dmaMMF_dmaMMF_mmTiles_1/*]
