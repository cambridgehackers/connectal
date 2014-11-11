
CONNECTALDIR?=../..
INTERFACES = NandSimRequest StrstrRequest NandSimIndication StrstrIndication
BSVFILES = $(CONNECTALDIR)/examples/nandsim/NandSim.bsv $(CONNECTALDIR)/examples/strstr/Strstr.bsv $(CONNECTALDIR)/examples/algo1_nandsim/Top.bsv $(CONNECTALDIR)/examples/nandsim/NandSimNames.bsv
CPPFILES=algo1.cpp
CPPFILES2=nandsim_manual.c
CONNECTALFLAGS += -D2 NO_CPP_PORTAL_CODE -lm -lblkid
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/strstr

include $(CONNECTALDIR)/Makefile.connectal
