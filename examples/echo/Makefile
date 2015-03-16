
CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request SwallowRequest:Swallow.request
H2S_INTERFACES = Echo:EchoIndication
BSVFILES = Echo.bsv Swallow.bsv
CPPFILES=testecho.cpp

CONNECTALFLAGS += -D IMPORT_HOSTIF
NUMBER_OF_MASTERS =0

## for testing fpgamake:
FPGAMAKE_CONNECTALFLAGS += -P mkEchoIndicationProxySynth -P mkEchoRequestWrapperMemPortalPipes

PORTAL_DUMP_MAP = "EchoIndication:EchoRequest:SwallowRequest"
AUTOTOP = --interface leds:Echo.leds

include $(CONNECTALDIR)/Makefile.connectal

