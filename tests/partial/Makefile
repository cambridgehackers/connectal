
CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication
BSVFILES = Echo.bsv
CPPFILES= testecho.cpp
NUMBER_OF_MASTERS =0

VARIANT?=1
PARTIAL_MODULE = Bounce
RECONFIG_MODULE = lEcho_bounce
CONNECTALFLAGS += -P mk$(PARTIAL_MODULE) --constraint=floorplan-$(BOARD).xdc -DRedefInstance=$(PARTIAL_MODULE)$(VARIANT)

partial.%:
	make build.$*
	make -C variant2

prebuild::
ifeq ($(VARIANT),1)
	VARIANT=2 PRTOP_FILE=../$(BOARD)/Impl/TopDown/top-post-route.dcp make gen.variant2
endif

include $(CONNECTALDIR)/Makefile.connectal

