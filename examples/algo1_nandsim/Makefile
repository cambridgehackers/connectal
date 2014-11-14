
CONNECTALDIR?=../..
INTERFACES = NandSimRequest StrstrRequest NandSimIndication StrstrIndication
BSVFILES = $(CONNECTALDIR)/lib/nandsim/bsv/NandSim.bsv $(CONNECTALDIR)/lib/strstr/bsv/Strstr.bsv Top.bsv $(CONNECTALDIR)/lib/nandsim/bsv/NandSimNames.bsv
CPPFILES=test.cpp
CPPFILES2=../nandsim/testnandsim.cpp
CONNECTALFLAGS += -D ALGO_NANDSIM
CONNECTALFLAGS += -D DEGPAR=2
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/strstr/cpp
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/nandsim/cpp


include $(CONNECTALDIR)/Makefile.connectal
