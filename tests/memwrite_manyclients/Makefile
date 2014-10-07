
MEMWRITEDIR=../../examples/memwrite
S2H = MemwriteRequest
H2S = MemwriteIndication
BSVFILES = $(MEMWRITEDIR)/Memwrite.bsv $(MEMWRITEDIR)/Top.bsv
CPPFILES = $(MEMWRITEDIR)/testmemwrite.cpp
CONNECTALFLAGS += -D NumEngineServers=16
CONNECTALFLAGS += --bscflags " -show-schedule"

#CONNECTALFLAGS += --bscflags " -ddumpschedule"
#CONNECTALFLAGS=--bscflags " -D TRACE_AXI"

include ../../Makefile.connectal
