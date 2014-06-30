
BSVDIR=../../bsv
S2H = MemwriteRequest DmaConfig
H2S = MemwriteIndication DmaIndication
BSVFILES = Memwrite.bsv Top.bsv
CPPFILES=testmemwrite.cpp
XBSVFLAGS += -D NumberOfMasters=4
#XBSVFLAGS=--bscflags " -D TRACE_AXI"

include ../../Makefile.common

