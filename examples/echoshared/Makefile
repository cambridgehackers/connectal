CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication
INTERFACES = MMURequest MMUIndication MemServerRequest MemServerIndication

BSVFILES = Echo.bsv $(CONNECTALDIR)/bsv/ConnectalMemory.bsv
CPPFILES=testecho.cpp $(CONNECTALDIR)/cpp/transportShared.c $(CONNECTALDIR)/cpp/dmaManager.c
CPPFILES2=daemon.cpp $(CONNECTALDIR)/cpp/transportShared.c $(CONNECTALDIR)/cpp/dmaManager.c
AUTOTOP = --portname MMURequestS2H --portname MMUIndicationH2S

include $(CONNECTALDIR)/Makefile.connectal
