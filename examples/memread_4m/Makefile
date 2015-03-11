
CONNECTALDIR?=../..
S2H_INTERFACES = MemreadRequest:Memread.request
H2S_INTERFACES = Memread:MemreadIndication::\`NumberOfMasters
MEM_INTERFACES = mkMemServerR:lMemread.dmaClients
BSVFILES = Memread.bsv
CPPFILES=testmemread.cpp

NUMBER_OF_MASTERS =4
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memread
#CONNECTALFLAGS=--bscflags " -D TRACE_AXI"
include $(CONNECTALDIR)/Makefile.connectal

