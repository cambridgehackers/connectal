
CONNECTALDIR?=../..
INTERFACES = MemreadRequest MemreadIndication
BSVFILES = Memread.bsv Top.bsv
CPPFILES=testmemread.cpp
NUMBER_OF_MASTERS =4
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memread
#CONNECTALFLAGS=--bscflags " -D TRACE_AXI"
include $(CONNECTALDIR)/Makefile.connectal

