
INTERFACES = NandSimRequest StrstrRequest NandSimIndication StrstrIndication
BSVFILES = ../../lib/bsv/NandSim.bsv ../../lib/bsv/Strstr.bsv Top.bsv ../../lib/bsv/NandSimNames.bsv
CPPFILES=test.cpp
CPPFILES2=../nandsim/testnandsim.cpp
CONNECTALFLAGS += -D DEGPAR=8
CONNECTALFLAGS += -D ALGO1_NANDSIM

include ../../Makefile.connectal
