CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request:host.derivedClock,host.derivedReset
H2S_INTERFACES = Echo:EchoIndication:host.derivedClock,host.derivedReset

BSVFILES = Echo.bsv
CPPFILES= ../echo/testecho.cpp
NUMBER_OF_MASTERS =0
CONNECTALFLAGS += -D IMPORT_HOST_CLOCKS

CONNECTALFLAGS += --mainclockperiod=20

include $(CONNECTALDIR)/Makefile.connectal
