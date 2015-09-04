CONNECTALDIR?=../..
S2H_INTERFACES = ReadTestRequest:ReadTest.request
H2S_INTERFACES = ReadTest:ReadTestIndication
MEM_READ_INTERFACES = lReadTest.dmaClient

BSVFILES = ReadTest.bsv
CPPFILES=memread_manual_manager.c
#CONNECTALFLAGS += -D NO_CPP_PORTAL_CODE -D NO_POLLER_SUPPORT

include $(CONNECTALDIR)/Makefile.connectal
