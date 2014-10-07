
MEMWRITEDIR=../../examples/memwrite
S2H = MemwriteRequest
H2S = MemwriteIndication
BSVFILES = $(MEMWRITEDIR)/Memwrite.bsv Top.bsv
CPPFILES = $(MEMWRITEDIR)/testmemwrite.cpp
XBSVFLAGS += -D NumEngineServers=16 -D DataBusWidth=128 -D NumberOfMasters=1
XBSVFLAGS += --bscflags " -show-schedule"

#XBSVFLAGS += --bscflags " -ddumpschedule"
#XBSVFLAGS=--bscflags " -D TRACE_AXI"

include ../../Makefile.connectal
