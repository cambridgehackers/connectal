
CONNECTALDIR?=../..
INTERFACES = MMURequest
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = EchoIndication:Echo
BSVFILES = Echo.bsv $(CONNECTALDIR)/bsv/ConnectalMemory.bsv
CPPFILES=testecho.cpp $(CONNECTALDIR)/cpp/portalShared.c $(CONNECTALDIR)/cpp/dmaManager.c

NUMBER_OF_MASTERS =0

include $(CONNECTALDIR)/Makefile.connectal

