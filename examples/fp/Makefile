
BSVDIR=../../bsv
S2H = FpRequest
H2S = FpIndication
BSVFILES = Fp.bsv Top.bsv
CPPFILES=testfp.cpp
XBSVFLAGS += -D NumberOfMasters=0

FP_ADD_V = $(XBSVDIR)/generated/xilinx/$(BOARD)/fp_add/fp_add_stub.v

prebuild:: $(FP_ADD_V) FpAdd.bsv

$(FP_ADD_V):
	(cd $(BOARD); vivado -mode batch -source ../synth-ip.tcl)

FpAdd.bsv:
	$(XBSVDIR)/scripts/importbvi.py -o FpAdd.bsv -c aclk -f s_axis_a -f s_axis_b -f m_axis_result -I FpAdd -P FpAdd $(FP_ADD_V)

include ../../Makefile.common
