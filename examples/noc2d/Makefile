
## hardware interfaces invoked from software (requests)
S2H = NocRequest
## software interfaces invoked from hardware (indications)
H2S = NocIndication
## all the BSV files to be scanned for types and interfaces
BSVFILES = Noc2d.bsv Top.bsv
## the source files in the example
CPPFILES=testnoc2d.cpp
## uncomment the following line to enable AXI trace
# XBSVFLAGS="--bscflags=-D TRACE_AXI"
XBSVFLAGS += --bscflags " -D NumberOfMasters=0"

include ../../Makefile.common

