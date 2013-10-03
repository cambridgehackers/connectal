BSVFLAGS = -aggressive-conditions -keep-fires -steps-warn-interval 1000000 -p +:../../bsv
SETTINGS_SH=/scratch/Xilinx/Vivado/2013.2/settings64.sh

test:
	bsc -sim -u -g mkTestBench $(BSVFLAGS) TestBench.bsv
	bsc -sim -o mkTestBench -e mkTestBench mkTestBench.ba

## -f compile_for_verilog -t generate_scemi_parameters
##	. $(SETTINGS_SH); build -v -f vivado
all: KC705.bsv
	. $(SETTINGS_SH); build -v kc705 -t vivado

verilog: KC705.bsv
	. $(SETTINGS_SH); build -v kc705 -f compile_for_verilog -t compile_for_verilog

.build/kc705/fpga/mkBridge/mkBridge.xpr: 
	build -v kc705 -f create_bspec_file -t prepare_project_files

vivado: .build/kc705/fpga/mkBridge/mkBridge.xpr
	. $(SETTINGS_SH); build -v kc705 -f vivado -t vivado

program:
	/scratch/jamey/bin/impact -batch impact.cmd
