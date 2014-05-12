
BSVDIR=../../bsv
S2H = PcieTestBenchRequest DmaConfig
H2S = PcieTestBenchIndication DmaIndication
BSVFILES = PcieTestBench.bsv Top.bsv
CPPFILES=testpcie.cpp
XBSVFLAGS += --bscflags " -D NumberOfMasters=0"
#XBSVFLAGS=--bscflags " -D TRACE_AXI"

include ../../Makefile.common
