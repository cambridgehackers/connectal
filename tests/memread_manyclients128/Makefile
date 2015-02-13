
CONNECTALDIR?=../..
MEMREADDIR=$(CONNECTALDIR)/examples/memread
INTERFACES = MemreadRequest MemreadIndication
BSVFILES = $(MEMREADDIR)/Memread.bsv
CPPFILES = $(MEMREADDIR)/testmemread.cpp
CONNECTALFLAGS += -D NumEngineServers=8 -D DataBusWidth=128
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memread
#CONNECTALFLAGS += --bscflags " -show-schedule"

AUTOTOP = -w MemreadRequest:Memread.request -p MemreadIndication:Memread
AUTOTOP += -m mkMemServerR:Memread.dmaClient

include $(CONNECTALDIR)/Makefile.connectal
