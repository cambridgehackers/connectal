
CONNECTALDIR?=../..
INTERFACES = NandSimRequest StrstrRequest NandSimIndication StrstrIndication
BSVFILES = $(CONNECTALDIR)/lib/bsv/NandSim.bsv $(CONNECTALDIR)/lib/bsv/Strstr.bsv Top.bsv $(CONNECTALDIR)/lib/bsv/NandSimNames.bsv
CPPFILES=test.cpp
CPPFILES2=../nandsim/testnandsim.cpp
CONNECTALFLAGS += -D ALGO1_NANDSIM
CONNECTALFLAGS += -D DEGPAR=2
CONNECTALFLAGS += -D HAYSTACKREADCLIENTS=2
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/strstr

include $(CONNECTALDIR)/Makefile.connectal
