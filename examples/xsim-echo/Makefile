
## hardware interfaces invoked from software (requests)
S2H = EchoRequest
## software interfaces invoked from hardware (indications)
H2S = EchoIndication
## all the BSV files to be scanned for types and interfaces
BSVFILES = Echo.bsv XsimTop.bsv
## the source files in the example
CPPFILES= testecho.cpp
## uncomment the following line to enable AXI trace
# XBSVFLAGS="--bscflags=-D TRACE_AXI"

TOP=XsimTop.bsv
MKTOP=mkXsimTop

include ../../Makefile.common

