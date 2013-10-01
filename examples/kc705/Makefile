BSVFLAGS = -aggressive-conditions -keep-fires -steps-warn-interval 1000000 -p +:../../bsv
SETTINGS_SH=/scratch/Xilinx/Vivado/2013.2/settings64.sh

test:
	bsc -sim -u -g mkTestBench $(BSVFLAGS) TestBench.bsv
	bsc -sim -o mkTestBench -e mkTestBench mkTestBench.ba

## -f compile_for_verilog -t generate_scemi_parameters
##	. $(SETTINGS_SH); build -v -f vivado
all: KC705.bsv
	. $(SETTINGS_SH); build -v kc705 -f compile_for_verilog

verilog: KC705.bsv
	. $(SETTINGS_SH); build -v kc705 -f compile_for_verilog -t compile_for_verilog

vivado: verilog
	cp -f synth-impl.tcl .build/kc705/fpga/
	echo create-subruns.pa.tcl for subruns
	. $(SETTINGS_SH); cd .build/kc705/fpga; vivado -mode batch -source synth-impl.tcl
