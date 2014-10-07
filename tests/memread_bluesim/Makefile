
MEMREADDIR=../../examples/memread
S2H = MemreadRequest
H2S = MemreadIndication
BSVFILES = Memread.bsv Top.bsv
CPPFILES = $(MEMREADDIR)/testmemread.cpp
CONNECTALFLAGS += -D NumEngineServers=16 -D DataBusWidth=128

#CONNECTALFLAGS += --bscflags " -show-schedule"
#CONNECTALFLAGS=--bscflags " -D TRACE_AXI"


include ../../Makefile.connectal
