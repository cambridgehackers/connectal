
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
read_verilog [ glob {verilog/top/*.v} ]
read_verilog [ glob /scratch/jamey/xbsv/xilinx/pcie_7x_v2_1/pcie_7x_0/source/*.v ]
read_verilog [ glob /scratch/jamey/xbsv/xilinx/7x/pcie/source/*.v ]
read_xdc {./constraints/vc707.xdc}

# STEP#2: run synthesis, report utilization and timing estimates, write checkpoint design
#
synth_design -name mkPcieTop -top mkPcieTop -part xc7vx485tffg1761-2 -flatten rebuilt

write_checkpoint -force $outputDir/mkpcietop_post_synth
