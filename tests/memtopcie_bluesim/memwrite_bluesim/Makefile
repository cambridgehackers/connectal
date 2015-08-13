
CONNECTALDIR?=../..
MEMWRITEDIR=$(CONNECTALDIR)/examples/memwrite
INTERFACES = MemwriteRequest MemwriteIndication
BSVFILES = $(MEMWRITEDIR)/Memwrite.bsv Top.bsv
CPPFILES = $(MEMWRITEDIR)/testmemwrite.cpp
CONNECTALFLAGS += -D NumEngineServers=16 -D DataBusWidth=128 -D NumberOfMasters=1
CONNECTALFLAGS += --bscflags " -show-schedule"
#CONNECTALFLAGS += --bscflags " -ddumpschedule"

include $(CONNECTALDIR)/Makefile.connectal
