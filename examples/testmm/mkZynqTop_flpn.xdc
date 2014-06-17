create_pblock mmtile_0
resize_pblock mmtile_0 -add {SLICE_X96Y270:SLICE_X171Y335 DSP48_X4Y108:DSP48_X6Y133 RAMB18_X5Y108:RAMB18_X8Y133 RAMB36_X5Y54:RAMB36_X8Y66}
endgroup
add_cells_to_pblock mmtile_0 [get_cells [list top_top_mm_dmaMMF_dmaMMF_mmTiles_0]] -clear_locs
