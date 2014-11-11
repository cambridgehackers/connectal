
CONNECTALDIR?=../..
INTERFACES = NandSimRequest StrstrRequest NandSimIndication StrstrIndication
BSVFILES = NandSimMod.bsv $(CONNECTALDIR)/lib/strstr/bsv/Strstr.bsv Top.bsv $(CONNECTALDIR)/lib/nandsim/bsv/NandSimNames.bsv
CPPFILES=$(CONNECTALDIR)/examples/algo1_nandsim/test.cpp
CPPFILES2=$(CONNECTALDIR)/examples/nandsim/testnandsim.cpp
CONNECTALFLAGS += -D ALGO_NANDSIM
CONNECTALFLAGS += -D DEGPAR=2
CONNECTALFLAGS += -D HAYSTACKREADCLIENTS=1
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/strstr/cpp
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/nandsim/cpp


include $(CONNECTALDIR)/Makefile.connectal
