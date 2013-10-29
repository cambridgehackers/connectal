BSVFLAGS = -aggressive-conditions -keep-fires -steps-warn-interval 1000000 -p +:../../bsv
SETTINGS_SH=/scratch/Xilinx/Vivado/2013.2/settings64.sh



test: tb
	./loadStoretestbench

## -f compile_for_verilog -t generate_scemi_parameters
##	. $(SETTINGS_SH); build -v -f vivado
all: LoadStoreWrapper.bsv .build/kc705
	. $(SETTINGS_SH); build -v kc705 -f compile_for_verilog -t vivado

.build/kc705:
	build -v kc705 -t make_build_dirs

verilog: LoadStoreWrapper.bsv LoadStoreTop.bsv
	. $(SETTINGS_SH); build -v kc705 -f compile_for_verilog -t compile_for_verilog

.build/kc705/fpga/mkLoadStoreTop/mkLoadStoreTop.xpr: 
	build -v kc705 -f create_bspec_file -t prepare_project_files

vivado: .build/kc705/fpga/mkLoadStoreTop/mkLoadStoreTop.xpr
	. $(SETTINGS_SH); build -v kc705 -f vivado -t vivado

program:
	/scratch/jamey/bin/impact -batch impact.cmd

clean:
	rm -fr .build *.bo

BSVOPTIONS = -aggressive-conditions -D SCEMI_CLOCK_PERIOD=10 -show-schedule -keep-inlined-boundaries -keep-fires -steps-warn-interval 1000000 -suppress-warnings G0046 -p +:../../bsv:../../examples/loadStore -keep-fires -parallel-sim-link 8

mkLoadStoreTestBench.ba: LoadStoreTestBench.bsv LoadStoreWrapper.bsv CoreLoadStoreRequestWrapper.bsv CoreLoadStoreIndicationWrapper.bsv
	rm -f mkLoadStoreTestBench.ba
	bsc -check-assert $(BSVOPTIONS) -sim -u -g mkLoadStoreTestBench LoadStoreTestBench.bsv

tb: mkLoadStoreTestBench.ba
	bsc -check-assert $(BSVOPTIONS) -sim -o loadStoretestbench -u -e mkLoadStoreTestBench mkLoadStoreTestBench.ba

mkLoadStoreTestBench.v: LoadStoreTestBench.bsv LoadStoreWrapper.bsv CoreLoadStoreRequestWrapper.bsv CoreLoadStoreIndicationWrapper.bsv
	bsc -check-assert $(BSVOPTIONS) -verilog -u -g mkLoadStoreTestBench LoadStoreTestBench.bsv
