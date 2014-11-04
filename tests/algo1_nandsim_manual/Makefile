## algo1_nandsim_manual


INTERFACES = NandSimRequest StrstrRequest NandSimIndication StrstrIndication
BSVFILES = ../../lib/bsv/NandSim.bsv ../../lib/bsv/Strstr.bsv ../../examples/algo1_nandsim/Top.bsv ../../lib/bsv/NandSimNames.bsv
#CPPFILES=algo1.cpp
CPPFILES=ss.cpp ss_hw.cpp
#CPPFILES=ss.cpp
CPPFILES2=nandsim_manual.c
CONNECTALFLAGS += -D2 NO_CPP_PORTAL_CODE -lm -lblkid

include ../../Makefile.connectal
