
# NOTE: typical usage would be "vivado -mode tcl -source create_mkPcieTop_batch.tcl" 
#
# STEP#0: define output directory area.
#
set outputDir ./hw
file mkdir $outputDir
#
# STEP#1: setup design sources and constraints
#
read_verilog [ glob {verilog/lib/*.v} ]
read_verilog [ glob {verilog/portal/*.v} ]
#read_xdc {./constraints/vc707.xdc}

# STEP#2: run synthesis, report utilization and timing estimates, write checkpoint design
#
synth_design -mode out_of_context -name mkPortalTopForPcie -top mkPortalTopForPcie -part xc7vx485tffg1761-2 -flatten rebuilt

write_checkpoint -force $outputDir/portaltop_post_synth

create_pblock pblock_top_portalTop_1
resize_pblock pblock_top_portalTop_1 -add {SLICE_X48Y150:SLICE_X173Y247 DSP48_X3Y60:DSP48_X16Y97 RAMB18_X4Y60:RAMB18_X10Y97 RAMB36_X4Y30:RAMB36_X10Y48}
add_cells_to_pblock pblock_top_portalTop_1 [get_cells *]

#read_xdc {constraints/vc707.xdc}

place_design
route_design

write_checkpoint -force $outputDir/portaltop_post_route
