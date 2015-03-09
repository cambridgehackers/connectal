
CONNECTALDIR?=../..
INTERFACES = EchoRequest EchoIndication MMURequest MMUIndication MemServerRequest MemServerIndication
BSVFILES = Echo.bsv Top.bsv
BSVFILES += $(CONNECTALDIR)/bsv/ConnectalMemory.bsv
CPPFILES=testecho.cpp $(CONNECTALDIR)/cpp/portalShared.c $(CONNECTALDIR)/cpp/dmaManager.c
CPPFILES2=daemon.cpp $(CONNECTALDIR)/cpp/portalShared.c $(CONNECTALDIR)/cpp/dmaManager.c

NUMBER_OF_MASTERS =0

include $(CONNECTALDIR)/Makefile.connectal
