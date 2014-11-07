
CONNECTALDIR?=../..
INTERFACES = Swallow EchoRequest EchoIndication MMURequest MMUIndication MemServerRequest MemServerIndication SharedMemoryPortalConfig
## all the BSV files to be scanned for types and interfaces
BSVFILES = Echo.bsv SwallowIF.bsv Top.bsv
## the source files in the example
CPPFILES=testecho.cpp $(CONNECTALDIR)/cpp/portalShared.c

include $(CONNECTALDIR)/Makefile.connectal

