BSVFLAGS = -aggressive-conditions -keep-fires -steps-warn-interval 1000000 -p +:../../bsv
SETTINGS_SH=/scratch/Xilinx/Vivado/2013.2/settings64.sh



test: tb
	./memcpytestbench

## -f compile_for_verilog -t generate_scemi_parameters
##	. $(SETTINGS_SH); build -v -f vivado
all: MemcpyWrapper.bsv .build/kc705
	. $(SETTINGS_SH); build -v kc705 -f compile_for_verilog -t vivado

.build/kc705:
	build -v kc705 -t make_build_dirs

verilog: MemcpyWrapper.bsv MemcpyTop.bsv
	. $(SETTINGS_SH); build -v kc705 -f compile_for_verilog -t compile_for_verilog

.build/kc705/fpga/mkMemcpyTop/mkMemcpyTop.xpr: 
	build -v kc705 -f create_bspec_file -t prepare_project_files

vivado: .build/kc705/fpga/mkMemcpyTop/mkMemcpyTop.xpr
	. $(SETTINGS_SH); build -v kc705 -f vivado -t vivado

program:
	/scratch/jamey/bin/impact -batch impact.cmd

clean:
	rm -fr .build *.bo

BSVOPTIONS = -aggressive-conditions -D SCEMI_CLOCK_PERIOD=10 -show-schedule -keep-inlined-boundaries -keep-fires -steps-warn-interval 1000000 -suppress-warnings G0046 -p +:../../bsv:../../examples/memcpy -keep-fires -parallel-sim-link 8

mkMemcpyTestBench.ba: MemcpyTestBench.bsv MemcpyWrapper.bsv CoreMemcpyRequestWrapper.bsv CoreMemcpyIndicationWrapper.bsv
	rm -f mkMemcpyTestBench.ba
	bsc -check-assert $(BSVOPTIONS) -sim -u -g mkMemcpyTestBench MemcpyTestBench.bsv

tb: mkMemcpyTestBench.ba
	bsc -check-assert $(BSVOPTIONS) -sim -o memcpytestbench -u -e mkMemcpyTestBench mkMemcpyTestBench.ba

mkMemcpyTestBench.v: MemcpyTestBench.bsv MemcpyWrapper.bsv CoreMemcpyRequestWrapper.bsv CoreMemcpyIndicationWrapper.bsv
	bsc -check-assert $(BSVOPTIONS) -verilog -u -g mkMemcpyTestBench MemcpyTestBench.bsv
