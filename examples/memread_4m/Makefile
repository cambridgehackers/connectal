
CONNECTALDIR?=../..
S2H_INTERFACES = MemreadRequest:Memread.request::\`NumberOfMasters
H2S_INTERFACES = MemreadIndication:Memread::\`NumberOfMasters
MEM_INTERFACES = MemServer.request:/lMemread.dmaClients,cons\(lMMU,nil\):PhysAddrWidth,DataBusWidth,\`NumberOfMasters:mkMemServerR
BSVFILES = Memread.bsv
CPPFILES=testmemread.cpp

NUMBER_OF_MASTERS =4
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memread
#CONNECTALFLAGS=--bscflags " -D TRACE_AXI"
include $(CONNECTALDIR)/Makefile.connectal

