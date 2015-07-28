startgroup
create_pblock pblock_ep7
resize_pblock pblock_ep7 -add {SLICE_X184Y54:SLICE_X221Y166 DSP48_X18Y22:DSP48_X19Y65 RAMB18_X12Y22:RAMB18_X14Y65 RAMB36_X12Y11:RAMB36_X14Y32}
add_cells_to_pblock pblock_ep7 [get_cells [list host_ep7]] -clear_locs
set_property HD.PARTPIN_RANGE {SLICE_X185Y54:SLICE_X186Y166} [get_pins host_ep7/*]
set_property CONTAIN_ROUTING true [get_pblocks pblock_ep7]
endgroup

startgroup
create_pblock pblock_pciehost
resize_pblock pblock_pciehost -add {SLICE_X112Y55:SLICE_X173Y197 DSP48_X9Y22:DSP48_X16Y77 RAMB18_X7Y22:RAMB18_X10Y77 RAMB36_X7Y11:RAMB36_X10Y38}
add_cells_to_pblock pblock_pciehost [get_cells [list host_pciehost]] -clear_locs
set_property HD.PARTPIN_RANGE {SLICE_X112Y55:SLICE_X113Y197} [get_pins host_pciehost/*]
set_property HD.PARTPIN_RANGE {SLICE_X172Y55:SLICE_X173Y197} [get_pins host_pciehost/*pci_re*]
set_property HD.PARTPIN_RANGE {SLICE_X172Y55:SLICE_X173Y197} [get_pins host_pciehost/*pci*]
set_property CONTAIN_ROUTING true [get_pblocks pblock_pciehost]
endgroup

# startgroup
# create_pblock pblock_pciehost
# resize_pblock pblock_pciehost -add {SLICE_X112Y55:SLICE_X221Y197 DSP48_X9Y22:DSP48_X19Y77 RAMB18_X7Y22:RAMB18_X14Y77 RAMB36_X7Y11:RAMB36_X14Y38}
# add_cells_to_pblock pblock_pciehost [get_cells [list host]] -clear_locs
# set_property HD.PARTPIN_RANGE {SLICE_X112Y55:SLICE_X113Y197} [get_pins host/*]
# endgroup

