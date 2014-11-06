## memread_manual

INTERFACES = MemreadRequest MemreadIndication
BSVFILES = Memread.bsv Top.bsv
#CPPFILES=testmemread.cpp
#CPPFILES=memread_manual.cpp
CPPFILES=memread_manual_manager.c
#CONNECTALFLAGS += --bscflags " -D TRACE_AXI"
CONNECTALFLAGS += -D NO_CPP_PORTAL_CODE

include ../../Makefile.connectal

