
BSVDIR=../../bsv
S2H = FpRequest
H2S = FpIndication
BSVFILES = Fp.bsv Top.bsv
CPPFILES=testfp.cpp
NUMBER_OF_MASTERS =0

FP_ADD_V = $(XBSVDIR)/generated/xilinx/$(BOARD)/fp_add/fp_add_stub.v

ifeq ($(BOARD),bluesim)
# not for bluesim
else

##
## the prebuild target will be made after the project directory is generated, e.g., by make gen.zedboard
##
prebuild:: $(FP_ADD_V) BviFpAdd.bsv

$(FP_ADD_V): synth-ip.tcl
	(cd $(BOARD); vivado -mode batch -source ../synth-ip.tcl)
endif

##
## Generate the import "BVI" from the generated stub for the core: fp_add_stub.v
##   Then, hand-modified so it works
BviFpAdd.bsv:
	$(XBSVDIR)/scripts/importbvi.py -o BviFpAdd.bsv -c aclk -f s_axis_a -f s_axis_b -f m_axis_result -I BviFpAdd -P BviFpAdd $(FP_ADD_V)

include ../../Makefile.common
