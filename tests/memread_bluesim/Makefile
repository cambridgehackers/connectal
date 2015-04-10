
CONNECTALDIR?=../..
MEMREADDIR=$(CONNECTALDIR)/examples/memread
INTERFACES = MemreadRequest MemreadIndication
BSVFILES = $(MEMREADDIR)/Memread.bsv Top.bsv
CPPFILES = $(MEMREADDIR)/testmemread.cpp
CONNECTALFLAGS += -D NumEngineServers=16 -D DataBusWidth=128
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memread
#CONNECTALFLAGS += --bscflags " -show-schedule"

include $(CONNECTALDIR)/Makefile.connectal
