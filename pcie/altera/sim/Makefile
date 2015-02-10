SHELL:=/bin/bash
PROJ=mkPcieS5Top
DIR=`pwd`/${PROJ}
CONNECTAL=../../../
#	qsys-generate --synthesis=VERILOG \
#        --simulation=VERILOG
all:
	qsys-generate --testbench=standard \
        --testbench-simulation=VERILOG \
        --output-directory=${DIR} \
        ${PROJ}.qsys
	@cp ${CONNECTAL}/out/de5/synthesis/altera_pcie_sv_hip_ast_wrapper.v mkPcieS5Top/testbench/mkPcieS5Top_tb/simulation/submodules/
	@cp ${CONNECTAL}/out/de5/synthesis/altera_pcie_reconfig_driver_wrapper.v mkPcieS5Top/testbench/mkPcieS5Top_tb/simulation/submodules/
	@cp ${CONNECTAL}/out/de5/synthesis/alt_xcvr_reconfig_wrapper.v mkPcieS5Top/testbench/mkPcieS5Top_tb/simulation/submodules/
	@cp ${CONNECTAL}/out/de5/synthesis/altera_pcie_hip_ast_ed.v mkPcieS5Top/testbench/mkPcieS5Top_tb/simulation/submodules/
	@cp ${CONNECTAL}/verilog/CONNECTNET.v mkPcieS5Top/testbench/mkPcieS5Top_tb/simulation/submodules/
	echo "Remember to generate the Pcie Hard IP Wrapper"
	#@cp ${CONNECTAL}/verilog/mkPcieS5Wrap.v mkPcieS5Top/testbench/mkPcieS5Top_tb/simulation/submodules/
	@cp bin/mkPcieS5Wrap.v mkPcieS5Top/testbench/mkPcieS5Top_tb/simulation/submodules/
	echo "Remember to generate the Pcie Hard IP Application Wrapper"
	#@cp ${CONNECTAL}/verilog/mkPcieS5Top.v mkPcieS5Top/testbench/mkPcieS5Top_tb/simulation/submodules/
	@cp bin/mkPcieS5Top.v mkPcieS5Top/testbench/mkPcieS5Top_tb/simulation/submodules/
	@cp bin/msim_setup.tcl mkPcieS5Top/testbench/mentor/
	cd mkPcieS5Top/testbench/mentor/; vsim -c -do "source msim_setup.tcl";

clean:
	rm -rf ${PROJ}
	rm *.csv *.spd *.sopcinfo
