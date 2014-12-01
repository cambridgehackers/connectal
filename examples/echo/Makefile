
CONNECTALDIR?=../..
INTERFACES = Swallow EchoRequest EchoIndication
## all the BSV files to be scanned for types and interfaces
BSVFILES = Echo.bsv SwallowIF.bsv Top.bsv
## the source files in the example
CPPFILES=testecho.cpp

CONNECTALFLAGS += -D IMPORT_HOSTIF
## uncomment the following line to enable AXI trace
#CONNECTALFLAGS += --bscflags " -D TRACE_AXI"
NUMBER_OF_MASTERS =0

## for testing fpgamake:
FPGAMAKE_CONNECTALFLAGS += -P mkEchoIndicationProxySynth -P mkEchoRequestWrapperMemPortalPipes

PORTAL_DUMP_MAP = "Swallow:EchoRequest:EchoIndication"

include $(CONNECTALDIR)/Makefile.connectal

