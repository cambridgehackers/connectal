
CONNECTALDIR?=../..
MEMREADDIR=$(CONNECTALDIR)/examples/memread
S2H_INTERFACES = MemreadRequest:Memread.request
H2S_INTERFACES = MemreadIndication:Memread
MEM_INTERFACES = MemServer.request:/lMemread.dmaClient,cons\(lMMU,nil\):PhysAddrWidth,DataBusWidth,\`NumberOfMasters:mkMemServerR
BSVFILES = $(MEMREADDIR)/Memread.bsv
CPPFILES = $(MEMREADDIR)/testmemread.cpp
CONNECTALFLAGS += -D NumEngineServers=16
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memread

include $(CONNECTALDIR)/Makefile.connectal
