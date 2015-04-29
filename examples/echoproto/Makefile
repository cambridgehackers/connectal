
CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication
BSVFILES = EchoIF.bsv
CPPFILES=testecho.cpp
CONNECTALFLAGS += --protobuf interface.proto

NUMBER_OF_MASTERS =0

## for testing fpgamake:
FPGAMAKE_CONNECTALFLAGS += -P mkEchoIndicationProxySynth -P mkEchoRequestWrapperMemPortalPipes

PORTAL_DUMP_MAP = "EchoIndication:EchoRequest:SwallowRequest"

include $(CONNECTALDIR)/Makefile.connectal

