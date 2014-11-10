
CONNECTALDIR?=../..
INTERFACES = NandSimRequest RegexpRequest RegexpIndication NandSimIndication
BSVFILES = $(CONNECTALDIR)/examples/nandsim/NandSim.bsv $(CONNECTALDIR)/examples/regexp/Regexp.bsv $(CONNECTALDIR)/examples/nandsim/NandSimNames.bsv Top.bsv 
CPPFILES=test.cpp
CPPFILES2=../nandsim/testnandsim.cpp
CONNECTALFLAGS += -D ALGO1_NANDSIM
CONNECTALFLAGS += -D HAYSTACKREADCLIENTS=1
CONNECTALFLAGS += -D DEGPAR=4 -D MAX_NUM_STATES=32 -D MAX_NUM_CHARS=32 

include $(CONNECTALDIR)/Makefile.connectal
