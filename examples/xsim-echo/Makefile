
CONNECTALDIR?=../..
INTERFACES = EchoRequest EchoIndication
## all the BSV files to be scanned for types and interfaces
BSVFILES = Echo.bsv XsimTop.bsv
## the source files in the example
CPPFILES= testecho.cpp
## uncomment the following to pass arguments to xelab and xsim
CONNECTALFLAGS += --xelabflags=--debug --xelabflags=typical --xsimflags=--tclbatch --xsimflags=../xsim.tcl --xsimflags=--onfinish --xsimflags=quit

TOP=XsimTop.bsv
MKTOP=mkXsimTop

include $(CONNECTALDIR)/Makefile.connectal

