
MEMWRITEDIR=../../examples/memwrite
S2H = MemwriteRequest
H2S = MemwriteIndication
BSVFILES = $(MEMWRITEDIR)/Memwrite.bsv Top.bsv
CPPFILES = $(MEMWRITEDIR)/testmemwrite.cpp
CONNECTALFLAGS += -D NumEngineServers=16 -D DataBusWidth=128 -D NumberOfMasters=1
CONNECTALFLAGS += --bscflags " -show-schedule"

#CONNECTALFLAGS += --bscflags " -ddumpschedule"
#CONNECTALFLAGS=--bscflags " -D TRACE_AXI"

include ../../Makefile.connectal
