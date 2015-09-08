CONNECTALDIR?=../..
MEMREADDIR=$(CONNECTALDIR)/examples/memread
S2H_INTERFACES = ReadTestRequest:ReadTest.request
H2S_INTERFACES = ReadTest:ReadTestIndication
MEM_READ_INTERFACES = lReadTest.dmaClient

BSVFILES = $(MEMREADDIR)/ReadTest.bsv
CPPFILES = $(MEMREADDIR)/testmemread.cpp
CONNECTALFLAGS += -D NumEngineServers=16
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memread

include $(CONNECTALDIR)/Makefile.connectal
