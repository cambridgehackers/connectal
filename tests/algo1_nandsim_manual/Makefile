
CONNECTALDIR?=../..
INTERFACES = NandCfgRequest StrstrRequest NandCfgIndication StrstrIndication
BSVFILES = $(CONNECTALDIR)/lib/nandsim/bsv/NandSim.bsv $(CONNECTALDIR)/lib/strstr/bsv/Strstr.bsv $(CONNECTALDIR)/examples/algo1_nandsim/Top.bsv $(CONNECTALDIR)/lib/nandsim/bsv/NandSimNames.bsv
CPPFILES=algo1.cpp
CPPFILES2=nandsim_manual.c
CONNECTALFLAGS += -D2 NO_CPP_PORTAL_CODE -lm
CONNECTALFLAGS += -D DEGPAR=2
# -lblkid
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/strstr/cpp
CONNECTALFLAGS += -DNO_POLLER_SUPPORT

include $(CONNECTALDIR)/Makefile.connectal
