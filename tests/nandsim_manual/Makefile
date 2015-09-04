CONNECTALDIR?=../..
S2H_INTERFACES = NandCfgRequest:NandSim.request
H2S_INTERFACES = NandSim:NandCfgIndication
MEM_READ_INTERFACES = lNandSim.readClient
MEM_WRITE_INTERFACES = lNandSim.writeClient

NANDLIB = ../../lib/nandsim
BSVFILES = $(NANDLIB)/bsv/NandSim.bsv
CPPFILES=testnandsim_test.cpp
#CPPFILES=testnandsim.cpp
#CPPFILES=nandsim_manual.c

include $(CONNECTALDIR)/Makefile.connectal
