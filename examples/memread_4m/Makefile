
BSVDIR=../../bsv
S2H = MemreadRequest DmaConfig
H2S = MemreadIndication DmaIndication
BSVFILES = Memread.bsv Top.bsv
CPPFILES=testmemread.cpp
XBSVFLAGS += -D NumberOfMasters=4
#XBSVFLAGS=--bscflags " -D TRACE_AXI"

include ../../Makefile.common

