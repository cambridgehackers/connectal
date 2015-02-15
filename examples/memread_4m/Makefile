
CONNECTALDIR?=../..
S2H_INTERFACES = MemreadRequest:Memread.request::\`NumberOfMasters
H2S_INTERFACES = MemreadIndication:Memread::\`NumberOfMasters
BSVFILES = Memread.bsv
CPPFILES=testmemread.cpp

AUTOTOP += -m mkMemServerR:Memread.dmaClients

NUMBER_OF_MASTERS =4
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memread
#CONNECTALFLAGS=--bscflags " -D TRACE_AXI"
include $(CONNECTALDIR)/Makefile.connectal

