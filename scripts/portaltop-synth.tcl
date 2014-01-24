
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
