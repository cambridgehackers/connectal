
CONNECTALDIR?=../..
MEMWRITEDIR=$(CONNECTALDIR)/examples/memwrite
S2H_INTERFACES = MemwriteRequest:Memwrite.request
H2S_INTERFACES = MemwriteIndication:Memwrite
MEM_INTERFACES = MemServer.request:/lMemwrite.dmaClient,cons\(lMMU,nil\):PhysAddrWidth,DataBusWidth,\`NumberOfMasters:mkMemServerW
BSVFILES = $(MEMWRITEDIR)/Memwrite.bsv
CPPFILES = $(MEMWRITEDIR)/testmemwrite.cpp
CONNECTALFLAGS += -D NumEngineServers=8 -D DataBusWidth=128
CONNECTALFLAGS += --bscflags " -show-schedule"
#CONNECTALFLAGS += --bscflags " -ddumpschedule"

include $(CONNECTALDIR)/Makefile.connectal
