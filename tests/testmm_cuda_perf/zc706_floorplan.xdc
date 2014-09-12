create_pblock mmtile_0
resize_pblock mmtile_0 -add {SLICE_X92Y150:SLICE_X96Y250 SLICE_X97Y150:SLICE_X161Y250 DSP48_X4Y62:DSP48_X6Y99 RAMB18_X5Y62:RAMB18_X7Y99 RAMB36_X5Y31:RAMB36_X7Y49}
add_cells_to_pblock mmtile_0 [get_cells [list top_mm_dmaMMF_dmaMMF_mmTiles_0]] -clear_locs
set_property CONTAIN_ROUTING true [get_pblocks mmtile_0]
set_property HD.PARTPIN_RANGE {SLICE_X92Y150:SLICE_X96Y250} [get_pins top_mm_dmaMMF_dmaMMF_mmTiles_0/*]

create_pblock mmtile_1
resize_pblock mmtile_1 -add {SLICE_X92Y52:SLICE_X96Y151 SLICE_X97Y52:SLICE_X159Y151 DSP48_X4Y22:DSP48_X6Y59 RAMB18_X4Y22:RAMB18_X7Y59 RAMB36_X4Y11:RAMB36_X7Y29}
add_cells_to_pblock mmtile_1 [get_cells [list top_mm_dmaMMF_dmaMMF_mmTiles_1]] -clear_locs
set_property CONTAIN_ROUTING true [get_pblocks mmtile_1]
set_property HD.PARTPIN_RANGE {SLICE_X92Y52:SLICE_X96Y151} [get_pins top_mm_dmaMMF_dmaMMF_mmTiles_1/*]
