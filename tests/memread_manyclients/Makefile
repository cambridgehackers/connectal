
CONNECTALDIR?=../..
MEMREADDIR=$(CONNECTALDIR)/examples/memread
S2H_INTERFACES = MemreadRequest:Memread.request
H2S_INTERFACES = Memread:MemreadIndication
MEM_INTERFACES = lMemread.dmaClient,nil
BSVFILES = $(MEMREADDIR)/Memread.bsv
CPPFILES = $(MEMREADDIR)/testmemread.cpp
CONNECTALFLAGS += -D NumEngineServers=16
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memread

include $(CONNECTALDIR)/Makefile.connectal
