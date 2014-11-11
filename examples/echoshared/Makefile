
CONNECTALDIR?=../..
INTERFACES = Swallow EchoRequest EchoIndication MMURequest MMUIndication MemServerRequest MemServerIndication
## all the BSV files to be scanned for types and interfaces
BSVFILES = Echo.bsv SwallowIF.bsv Top.bsv
BSVFILES += $(CONNECTALDIR)/bsv/ConnectalMemory.bsv
## the source files in the example
CPPFILES=daemon.cpp $(CONNECTALDIR)/cpp/portalShared.c $(CONNECTALDIR)/cpp/dmaManager.c
CPPFILES2=testecho.cpp $(CONNECTALDIR)/cpp/portalShared.c $(CONNECTALDIR)/cpp/dmaManager.c

NUMBER_OF_MASTERS =0

include $(CONNECTALDIR)/Makefile.connectal
