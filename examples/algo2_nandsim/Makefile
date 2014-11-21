
CONNECTALDIR?=../..
INTERFACES = NandCfgRequest RegexpRequest NandCfgIndication RegexpIndication
BSVFILES = $(CONNECTALDIR)/lib/nandsim/bsv/NandSim.bsv $(CONNECTALDIR)/lib/regexp/bsv/Regexp.bsv $(CONNECTALDIR)/lib/nandsim/bsv/NandSimNames.bsv Top.bsv 
CPPFILES=test.cpp
CPPFILES2=../nandsim/testnandsim.cpp
CONNECTALFLAGS += -D HAYSTACKREADCLIENTS=1
CONNECTALFLAGS += -D DEGPAR=4 -D MAX_NUM_STATES=32 -D MAX_NUM_CHARS=32 
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/regexp/cpp
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/nandsim/cpp
CONNECTALFLAGS += -D ALGO_NANDSIM

include $(CONNECTALDIR)/Makefile.connectal
