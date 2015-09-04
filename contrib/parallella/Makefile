CONNECTALDIR?=../..
#S2H_INTERFACES = MainRequest:Main.request
#H2S_INTERFACES = Main:MainRequest

BSVFILES = ELink.bsv ParallellaLibDefs.bsv
CPPFILES=testmain.cpp
PARDIR=/scratch/stewart/parallella/parallella-hw/fpga/src
PIN_TYPE = ParallellaLibDefs::ParallellaPins
PIN_TYPE_INCLUDE = ParallellaLibDefs
# CONNECTALFLAGS = -C /scratch/stewart/parallella/parallella-hw/boards/parallella-I/constraints/parallella_z70x0_loc.xdc
CONNECTALFLAGS += \
	--verilog $(PARDIR)/elink/hdl/elink_regmap.v \
	--verilog $(PARDIR)/constants/hdl \
	--verilog $(PARDIR)/elink/hdl \
	--verilog $(PARDIR)/embox/hdl \
	--verilog $(PARDIR)/emmu/hdl \
	--verilog $(PARDIR)/gpio/hdl \
	--verilog $(PARDIR)/i2c/hdl \
	--verilog $(PARDIR)/memory/hdl \
	--verilog $(PARDIR)/stubs/hdl 




CONNECTALFLAGS += -D IMPORT_HOSTIF

Parallella.bsv: parallella.v
	$(CONNECTALDIR)/generated/scripts/importbvi.py -o Parallella.bsv -I Parallella -P PP --factor esaxi --factor emaxi --factor rx --factor tx -c clkin_100 -r reset \
	-p SIDW:12 \
	-p SAW:32 \
	-p SDW:32 \
	-p MIDW:6 \
	-p MAW:32 \
	-p MDW:64 \
	-p STW:8 \
	-p LW:8 \
	-p AW:32 \
	-p DW:32 \
	parallella.v

include $(CONNECTALDIR)/Makefile.connectal
