
CONNECTALDIR?=../..
INTERFACES = MMURequest
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication
BSVFILES = Echo.bsv $(CONNECTALDIR)/bsv/ConnectalMemory.bsv
CPPFILES=testecho.cpp $(CONNECTALDIR)/cpp/transportShared.c $(CONNECTALDIR)/cpp/dmaManager.c

NUMBER_OF_MASTERS =0

include $(CONNECTALDIR)/Makefile.connectal

