CONNECTALDIR?=../..
S2H_INTERFACES = IpcTestRequest:IpcTest.request
H2S_INTERFACES = IpcTest:IpcTestIndication

BSVFILES = IpcTest.bsv
CPPFILES=testipctest.cpp
NUMBER_OF_MASTERS =0
## for testing fpgamake:
FPGAMAKE_CONNECTALFLAGS += -P mkIpcTestIndicationProxySynth -P mkIpcTestRequestWrapperMemPortalPipes

include $(CONNECTALDIR)/Makefile.connectal
