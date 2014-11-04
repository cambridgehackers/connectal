
MEMREADDIR=../../examples/memread
INTERFACES = MemreadRequest MemreadIndication
BSVFILES = $(MEMREADDIR)/Memread.bsv $(MEMREADDIR)/Top.bsv
CPPFILES = $(MEMREADDIR)/testmemread.cpp
CONNECTALFLAGS += -D NumEngineServers=16 -D DataBusWidth=128

#CONNECTALFLAGS += --bscflags " -show-schedule"
#CONNECTALFLAGS=--bscflags " -D TRACE_AXI"


include ../../Makefile.connectal
