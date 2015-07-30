CONNECTALDIR?=../..
S2H_INTERFACES = NandCfgRequest:NandSim.request
H2S_INTERFACES = NandSim:NandCfgIndication
MEM_INTERFACES = lNandSim.readClient,lNandSim.writeClient

BSVFILES = $(CONNECTALDIR)/lib/nandsim/bsv/NandSim.bsv
CPPFILES=testnandsim.cpp
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/nandsim/cpp

include $(CONNECTALDIR)/Makefile.connectal
