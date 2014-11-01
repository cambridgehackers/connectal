
INTERFACES = Swallow EchoRequest EchoIndication EchoRequest EchoIndication MMUConfigRequest MMUConfigIndication
## all the BSV files to be scanned for types and interfaces
BSVFILES = Echo.bsv Swallow.bsv Top.bsv
BSVFILES += $(CONNECTALDIR)/bsv/ConnectalMemory.bsv
## the source files in the example
CPPFILES=daemon.cpp
CPPFILES2=testecho.cpp

NUMBER_OF_MASTERS =0

include ../../Makefile.connectal
