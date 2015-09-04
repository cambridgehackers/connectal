CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request:host
H2S_INTERFACES = Echo:EchoIndication:host

BSVFILES = ../echo/Echo.bsv
CPPFILES= ../echo/testecho.cpp
## for testing fpgamake:
FPGAMAKE_CONNECTALFLAGS += -P mkEchoIndicationProxySynth -P mkEchoRequestWrapperMemPortalPipes
PORTAL_DUMP_MAP = "EchoIndication:EchoRequest:SwallowRequest"
CONNECTALFLAGS += -D IMPORT_HOSTIF

include $(CONNECTALDIR)/Makefile.connectal
