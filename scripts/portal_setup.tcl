# NOTE: typical usage would be "vivado -mode tcl -source create_mkPcieTop_batch.tcl" 
#
# STEP#0: define output directory area.
#
set outputDir ./hw
file mkdir $outputDir
#
# STEP#1: setup design sources and constraints
#
source board.tcl
source $xbsvdir/scripts/xilinx/tcl/log.tcl

####Report and DCP controls - values: 0-required min; 1-few extra; 2-all
set verbose      2
set dcpLevel     1

### logs
set runLog "run"
set commandLog "command"
set criticalLog "critical"
set logs [list $runLog $commandLog $criticalLog]
set rfh [open "$runLog.log" w]
set cfh [open "$commandLog.log" w]
set wfh [open "$criticalLog.log" w]

create_project -in_memory -part $partname
read_verilog [ glob {verilog/*.v} ]
