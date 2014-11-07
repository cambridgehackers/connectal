
CONNECTALDIR?=../..
INTERFACES = NandSimRequest StrstrRequest NandSimIndication StrstrIndication
BSVFILES = $(CONNECTALDIR)/lib/bsv/NandSim.bsv $(CONNECTALDIR)/lib/bsv/Strstr.bsv $(CONNECTALDIR)/examples/algo1_nandsim/Top.bsv $(CONNECTALDIR)/lib/bsv/NandSimNames.bsv
CPPFILES=algo1.cpp
CPPFILES2=nandsim_manual.c
CONNECTALFLAGS += -D2 NO_CPP_PORTAL_CODE -lm -lblkid

include $(CONNECTALDIR)/Makefile.connectal
