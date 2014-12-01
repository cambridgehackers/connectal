
CONNECTALDIR?=../..
INTERFACES = IpcTestRequest IpcTestIndication
BSVFILES = IpcTest.bsv Top.bsv
CPPFILES=testipctest.cpp

CONNECTALFLAGS += -D IMPORT_HOSTIF
NUMBER_OF_MASTERS =0

## for testing fpgamake:
FPGAMAKE_CONNECTALFLAGS += -P mkIpcTestIndicationProxySynth -P mkIpcTestRequestWrapperMemPortalPipes

include $(CONNECTALDIR)/Makefile.connectal

