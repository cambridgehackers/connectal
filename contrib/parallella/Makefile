
CONNECTALDIR?=../..
#S2H_INTERFACES = MainRequest:Main.request
#H2S_INTERFACES = Main:MainRequest
BSVFILES = PParallella.bsv Parallella.bsv Top.bsv
#CPPFILES=testmain.cpp
NUMBER_OF_MASTERS =0

PARDIR=/scratch/stewart/parallella/parallella-hw/fpga/hdl

CONNECTAL_FLAGS += \
	--verilob $(PARDIR)/parallella-I \
	--verilog $(PARDIR)/elink-gold

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

