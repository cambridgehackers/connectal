
CONNECTALDIR?=../..
INTERFACES = Swallow EchoRequest EchoIndication MMURequest MMUIndication
## all the BSV files to be scanned for types and interfaces
BSVFILES = Echo.bsv SwallowIF.bsv Top.bsv
BSVFILES += $(CONNECTALDIR)/bsv/ConnectalMemory.bsv
## the source files in the example
CPPFILES=daemon.cpp
CPPFILES2=testecho.cpp

NUMBER_OF_MASTERS =0

include $(CONNECTALDIR)/Makefile.connectal
