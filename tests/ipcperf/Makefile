
CONNECTALDIR?=../..
INTERFACES = Swallow EchoRequest EchoIndication
BSVFILES = Echo.bsv SwallowIF.bsv Top.bsv
CPPFILES=testecho.cpp

CONNECTALFLAGS += -D IMPORT_HOSTIF
NUMBER_OF_MASTERS =0

## for testing fpgamake:
FPGAMAKE_CONNECTALFLAGS += -P mkEchoIndicationProxySynth -P mkEchoRequestWrapperMemPortalPipes

include $(CONNECTALDIR)/Makefile.connectal

