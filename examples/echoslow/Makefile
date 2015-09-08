CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication:host.derivedClock,host.derivedReset

BSVFILES = Echo.bsv
CPPFILES= ../echo/testecho.cpp
CONNECTALFLAGS += -D IMPORT_HOST_CLOCKS
CONNECTALFLAGS += --mainclockperiod=20

include $(CONNECTALDIR)/Makefile.connectal
