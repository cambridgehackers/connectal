
CONNECTALDIR?=../..
INTERFACES = NandSimRequest StrstrRequest NandSimIndication StrstrIndication
BSVFILES = $(CONNECTALDIR)/examples/nandsim/NandSim.bsv $(CONNECTALDIR)/examples/strstr/Strstr.bsv Top.bsv $(CONNECTALDIR)/examples/nandsim/NandSimNames.bsv
CPPFILES=test.cpp
CPPFILES2=../nandsim/testnandsim.cpp
CONNECTALFLAGS += -D ALGO1_NANDSIM
CONNECTALFLAGS += -D DEGPAR=2
CONNECTALFLAGS += -D HAYSTACKREADCLIENTS=1
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/strstr


include $(CONNECTALDIR)/Makefile.connectal
