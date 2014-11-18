
CONNECTALDIR?=../..
INTERFACES = NandSimRequest NandSimIndication
BSVFILES = $(CONNECTALDIR)/lib/nandsim/bsv/NandSim.bsv $(CONNECTALDIR)/lib/nandsim/bsv/NandSimNames.bsv Top.bsv
CPPFILES=testnandsim.cpp
#CONNECTALFLAGS=--bscflags " -D TRACE_AXI"
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/nandsim/cpp

include $(CONNECTALDIR)/Makefile.connectal
