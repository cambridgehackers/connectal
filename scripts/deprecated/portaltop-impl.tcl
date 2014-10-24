
# NOTE: typical usage would be "vivado -mode tcl -source create_mkPcieTop_batch.tcl" 
#
# STEP#0: define output directory area.
#
if [file exists {board.tcl}] {
    source {board.tcl}
} else {
    set boardname vc707
    set partname {xc7vx485tffg1761-2}
}

set outputDir ./hw
file mkdir $outputDir
#
# STEP#1: setup design sources and constraints
#
read_verilog [ glob {verilog/lib/*.v} ]
read_verilog [ glob {verilog/portal/*.v} ]

# STEP#2: run synthesis, report utilization and timing estimates, write checkpoint design
#
synth_design -mode out_of_context -name mkConnectalTopForPcie -top mkConnectalTopForPcie -part $partname -flatten rebuilt

write_checkpoint -force $outputDir/portaltop_post_synth

read_xdc $connectaldir/constraints/$boardname-portal-pblock.xdc

place_design
route_design

write_checkpoint -force $outputDir/portaltop_post_route
