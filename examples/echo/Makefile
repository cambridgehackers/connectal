
## hardware interfaces invoked from software (requests)
S2H = Swallow EchoRequest
## software interfaces invoked from hardware (indications)
H2S = EchoIndication
## all the BSV files to be scanned for types and interfaces
BSVFILES = Echo.bsv Swallow.bsv Top.bsv
## the source files in the example
CPPFILES=testecho.cpp
## uncomment the following line to enable AXI trace
#XBSVFLAGS += --bscflags " -D TRACE_AXI"
XBSVFLAGS += --bscflags " -D NumberOfMasters=0"

include ../../Makefile.common

