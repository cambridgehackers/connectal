
MEMREADDIR=../../examples/memread
S2H = MemreadRequest
H2S = MemreadIndication
BSVFILES = $(MEMREADDIR)/Memread.bsv $(MEMREADDIR)/Top.bsv
CPPFILES = $(MEMREADDIR)/testmemread.cpp
XBSVFLAGS += -D NumEngineServers=16 -D DataBusWidth=128

#XBSVFLAGS += --bscflags " -show-schedule"
#XBSVFLAGS=--bscflags " -D TRACE_AXI"


include ../../Makefile.connectal
