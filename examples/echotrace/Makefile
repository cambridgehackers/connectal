
CONNECTALDIR?=../..
INTERFACES = EchoRequest EchoIndication MMURequest
BSVFILES = Echo.bsv Top.bsv $(CONNECTALDIR)/bsv/ConnectalMemory.bsv
CPPFILES=testecho.cpp $(CONNECTALDIR)/cpp/portalShared.c $(CONNECTALDIR)/cpp/dmaManager.c

NUMBER_OF_MASTERS =0

include $(CONNECTALDIR)/Makefile.connectal

