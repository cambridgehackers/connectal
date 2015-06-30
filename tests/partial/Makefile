
CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication
BSVFILES = Echo.bsv
CPPFILES= testecho.cpp
NUMBER_OF_MASTERS =0

VARIANT?=1
PARTIAL_MODULE = Bounce
CONNECTALFLAGS += -P mk$(PARTIAL_MODULE) --floorplan=floorplan.xdc -DRedefInstance=$(PARTIAL_MODULE)$(VARIANT)

partial.%:
	make gen.$*
	make -C $* synth.mk$(PARTIAL_MODULE) synth.mkZynqTop
	make -C variant2 synth.mk$(PARTIAL_MODULE)
	vivado -mode batch -source reconf.tcl

prebuild::
ifeq ($(VARIANT),1)
	VARIANT=2 PRTOP_FILE=../$(BOARD)/Impl/Reconf/top-post-route.dcp make gen.variant2
endif

zc702/Impl/Reconf/top-post-route.dcp:

include $(CONNECTALDIR)/Makefile.connectal

