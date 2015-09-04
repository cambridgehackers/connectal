CONNECTALDIR?=../..
INTERFACES = MMURequest
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication

BSVFILES = Echo.bsv $(CONNECTALDIR)/bsv/ConnectalMemory.bsv
CPPFILES=testecho.cpp $(CONNECTALDIR)/cpp/transportShared.c $(CONNECTALDIR)/cpp/dmaManager.c

include $(CONNECTALDIR)/Makefile.connectal
