BSVFLAGS = -aggressive-conditions -keep-fires -steps-warn-interval 1000000 -p +:../../bsv
SETTINGS_SH=/scratch/Xilinx/Vivado/2013.2/settings64.sh

test:
	bsc -sim -u -g mkTestBench $(BSVFLAGS) TestBench.bsv
	bsc -sim -o mkTestBench -e mkTestBench mkTestBench.ba

## -f compile_for_verilog -t generate_scemi_parameters
##	. $(SETTINGS_SH); build -v -f vivado
all: KC705.bsv
	. $(SETTINGS_SH); build -v kc705 -f compile_for_verilog

shortcut: KC705.bsv
	. $(SETTINGS_SH); build -v kc705 -f compile_for_verilog -t compile_for_verilog
	. $(SETTINGS_SH); build -v kc705 -f vivado

