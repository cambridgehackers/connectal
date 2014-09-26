
MEMWRITEDIR=../../examples/memwrite
S2H = MemwriteRequest
H2S = MemwriteIndication
BSVFILES = $(MEMWRITEDIR)/Memwrite.bsv $(MEMWRITEDIR)/Top.bsv
CPPFILES = $(MEMWRITEDIR)/testmemwrite.cpp
XBSVFLAGS += -D NumEngineServers=32 -D DataBusWidth=128
XBSVFLAGS += --bscflags " -show-schedule"

#XBSVFLAGS += --bscflags " -ddumpschedule"
#XBSVFLAGS=--bscflags " -D TRACE_AXI"

include ../../Makefile.xbsv
