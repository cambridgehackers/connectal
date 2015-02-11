
CONNECTALDIR?=../..
INTERFACES = MemreadRequest MemreadIndication
BSVFILES = Memread.bsv
CPPFILES=testmemread.cpp

AUTOTOP = -w MemreadRequest:Memread.request::\`NumberOfMasters -p MemreadIndication:Memread::\`NumberOfMasters
AUTOTOP += -m mkMemServerR:Memread.dmaClients

NUMBER_OF_MASTERS =4
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memread
#CONNECTALFLAGS=--bscflags " -D TRACE_AXI"
include $(CONNECTALDIR)/Makefile.connectal

