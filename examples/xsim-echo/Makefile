
## hardware interfaces invoked from software (requests)
S2H = EchoRequest
## software interfaces invoked from hardware (indications)
H2S = EchoIndication
## all the BSV files to be scanned for types and interfaces
BSVFILES = Echo.bsv XsimTop.bsv
## the source files in the example
CPPFILES= testecho.cpp
## uncomment the following line to enable AXI trace
# XBSVFLAGS+="--bscflags=-D TRACE_AXI"
## uncomment the following to pass arguments to xelab and xsim
XBSVFLAGS += --xelabflags=--debug --xelabflags=typical --xsimflags=--tclbatch --xsimflags=../xsim.tcl --xsimflags=--onfinish --xsimflags=quit

TOP=XsimTop.bsv
MKTOP=mkXsimTop

include ../../Makefile.connectal

