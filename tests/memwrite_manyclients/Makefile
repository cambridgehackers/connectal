
MEMWRITEDIR=../../examples/memwrite
S2H = MemwriteRequest DmaConfig
H2S = MemwriteIndication DmaIndication
BSVFILES = $(MEMWRITEDIR)/Memwrite.bsv $(MEMWRITEDIR)/Top.bsv
CPPFILES = $(MEMWRITEDIR)/testmemwrite.cpp
XBSVFLAGS += -D NumEngineServers=32

include ../../Makefile.common
