
CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication
BSVFILES = Echo.bsv
CPPFILES= testecho.cpp
NUMBER_OF_MASTERS =0

CONNECTALFLAGS += -P mkBounce1 --floorplan=floorplan.xdc

include $(CONNECTALDIR)/Makefile.connectal

