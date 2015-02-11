
CONNECTALDIR?=../..
INTERFACES = SwallowRequest EchoRequest EchoIndication
BSVFILES = Echo.bsv Swallow.bsv
CPPFILES=testecho.cpp

CONNECTALFLAGS += -D IMPORT_HOSTIF
NUMBER_OF_MASTERS =0

## for testing fpgamake:
FPGAMAKE_CONNECTALFLAGS += -P mkEchoIndicationProxySynth -P mkEchoRequestWrapperMemPortalPipes

PORTAL_DUMP_MAP = "EchoIndication:EchoRequest:SwallowRequest"
AUTOTOP = -l Echo -w EchoRequest:Echo.request -w SwallowRequest:Swallow.request -p EchoIndication:Echo

include $(CONNECTALDIR)/Makefile.connectal

