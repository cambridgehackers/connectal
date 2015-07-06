
CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication
BSVFILES = Echo.bsv
CPPFILES= testecho.cpp
NUMBER_OF_MASTERS =0

VARIANT?=1
VARIANT_LIST = 2 3
PARTIAL_MODULE = Bounce
RECONFIG_MODULE = lEcho_bounce
CONNECTALFLAGS += -P mk$(PARTIAL_MODULE) --constraint=floorplan-$(BOARD).xdc -DRedefInstance=$(PARTIAL_MODULE)$(VARIANT)

include $(CONNECTALDIR)/Makefile.connectal
