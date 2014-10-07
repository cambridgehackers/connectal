
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
read_verilog [ glob {verilog/top/*.v} ]
read_verilog [ glob $connectaldir/xilinx/pcie_7x_v2_1/pcie_7x_0/source/*.v ]
read_verilog [ glob $connectaldir/xilinx/7x/pcie/source/*.v ]
read_xdc constraints/$boardname.xdc

# STEP#2: run synthesis, report utilization and timing estimates, write checkpoint design
#
synth_design -name mkPcieTop -top mkPcieTop -part $partname -flatten rebuilt

write_checkpoint -force $outputDir/mkpcietop_post_synth
