
MEMREADDIR=../../examples/memread
S2H = MemreadRequest DmaConfig
H2S = MemreadIndication DmaIndication
BSVFILES = $(MEMREADDIR)/Memread.bsv $(MEMREADDIR)/Top.bsv
CPPFILES = $(MEMREADDIR)/testmemread.cpp
XBSVFLAGS += -D NumEngineServers=32

include ../../Makefile.common
