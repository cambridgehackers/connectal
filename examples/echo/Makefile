
## hardware interfaces invoked from software (requests)
S2H = Swallow EchoRequest
## software interfaces invoked from hardware (indications)
H2S = EchoIndication
## all the BSV files to be scanned for types and interfaces
BSVFILES = Echo.bsv Swallow.bsv Top.bsv
## the source files in the example
CPPFILES=testecho.cpp

XBSVFLAGS += -D IMPORT_HOSTIF
## uncomment the following line to enable AXI trace
#XBSVFLAGS += --bscflags " -D TRACE_AXI"
NUMBER_OF_MASTERS =0

## for testing fpgamake:
FPGAMAKE_XBSVFLAGS += -P mkEchoIndicationProxySynth -P mkEchoRequestWrapperMemPortalPipes

include ../../Makefile.common

