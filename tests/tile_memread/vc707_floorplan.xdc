startgroup
create_pblock pblock_ep7
resize_pblock pblock_ep7 -add {SLICE_X184Y54:SLICE_X221Y166 DSP48_X18Y22:DSP48_X19Y65 RAMB18_X12Y22:RAMB18_X14Y65 RAMB36_X12Y11:RAMB36_X14Y32}
add_cells_to_pblock pblock_ep7 [get_cells [list ep7]] -clear_locs
endgroup

startgroup
create_pblock pblock_pciehost
resize_pblock pblock_pciehost -add {SLICE_X112Y55:SLICE_X171Y197 DSP48_X9Y22:DSP48_X16Y77 RAMB18_X7Y22:RAMB18_X10Y77 RAMB36_X7Y11:RAMB36_X10Y38 BUFGCTRL_X0Y16}
add_cells_to_pblock pblock_pciehost [get_cells [list pciehost]] -clear_locs
endgroup

startgroup
create_pblock pblock_portalTop
resize_pblock pblock_portalTop -add {SLICE_X0Y25:SLICE_X101Y247 DSP48_X0Y10:DSP48_X7Y97 RAMB18_X0Y10:RAMB18_X6Y97 RAMB36_X0Y5:RAMB36_X6Y48}
add_cells_to_pblock pblock_portalTop [get_cells [list portalTop]] -clear_locs
endgroup
