BSVFLAGS = -aggressive-conditions -keep-fires -steps-warn-interval 1000000 -p +:../../bsv
SETTINGS_SH=/scratch/Xilinx/Vivado/2013.2/settings64.sh



test: tb
	./echotestbench

## -f compile_for_verilog -t generate_scemi_parameters
##	. $(SETTINGS_SH); build -v -f vivado
all: EchoWrapper.bsv .build/kc705
	. $(SETTINGS_SH); build -v kc705 -f compile_for_verilog -t vivado

.build/kc705:
	build -v kc705 -t make_build_dirs

verilog: EchoWrapper.bsv EchoTop.bsv
	. $(SETTINGS_SH); build -v kc705 -f compile_for_verilog -t compile_for_verilog

.build/kc705/fpga/mkEchoTop/mkEchoTop.xpr: 
	build -v kc705 -f create_bspec_file -t prepare_project_files

vivado: .build/kc705/fpga/mkEchoTop/mkEchoTop.xpr
	. $(SETTINGS_SH); build -v kc705 -f vivado -t vivado

program:
	/scratch/jamey/bin/impact -batch impact.cmd

clean:
	rm -fr .build *.bo

BSVOPTIONS = -aggressive-conditions -D SCEMI_CLOCK_PERIOD=10 -show-schedule -keep-inlined-boundaries -keep-fires -steps-warn-interval 1000000 -suppress-warnings G0046 -p +:../../bsv:../../examples/echo -keep-fires -parallel-sim-link 8

mkEchoTestBench.ba: EchoTestBench.bsv EchoWrapper.bsv CoreEchoRequestWrapper.bsv CoreEchoIndicationWrapper.bsv
	rm -f mkEchoTestBench.ba
	bsc -check-assert $(BSVOPTIONS) -sim -u -g mkEchoTestBench EchoTestBench.bsv

tb: mkEchoTestBench.ba
	bsc -check-assert $(BSVOPTIONS) -sim -o echotestbench -u -e mkEchoTestBench mkEchoTestBench.ba

mkEchoTestBench.v: EchoTestBench.bsv EchoWrapper.bsv CoreEchoRequestWrapper.bsv CoreEchoIndicationWrapper.bsv
	bsc -check-assert $(BSVOPTIONS) -verilog -u -g mkEchoTestBench EchoTestBench.bsv
