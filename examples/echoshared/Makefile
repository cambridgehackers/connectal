
CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = EchoIndication:Echo
INTERFACES = MMURequest MMUIndication MemServerRequest MemServerIndication
BSVFILES = Echo.bsv
BSVFILES += $(CONNECTALDIR)/bsv/ConnectalMemory.bsv
CPPFILES=testecho.cpp $(CONNECTALDIR)/cpp/portalShared.c $(CONNECTALDIR)/cpp/dmaManager.c
CPPFILES2=daemon.cpp $(CONNECTALDIR)/cpp/portalShared.c $(CONNECTALDIR)/cpp/dmaManager.c

NUMBER_OF_MASTERS =0
AUTOTOP = --portname MMURequestS2H --portname MMUIndicationH2S

include $(CONNECTALDIR)/Makefile.connectal
