
CONNECTALDIR?=../..
MEMWRITEDIR=$(CONNECTALDIR)/examples/memwrite
INTERFACES = MemwriteRequest MemwriteIndication
BSVFILES = $(MEMWRITEDIR)/Memwrite.bsv
CPPFILES = $(MEMWRITEDIR)/testmemwrite.cpp
CONNECTALFLAGS += -D NumEngineServers=8 -D DataBusWidth=128
CONNECTALFLAGS += --bscflags " -show-schedule"
#CONNECTALFLAGS += --bscflags " -ddumpschedule"

AUTOTOP = -w MemwriteRequest:Memwrite.request -p MemwriteIndication:Memwrite
AUTOTOP += -m mkMemServerW:Memwrite.dmaClient

include $(CONNECTALDIR)/Makefile.connectal
