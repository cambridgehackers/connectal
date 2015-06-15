
CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication
BSVFILES = Echo.bsv
CPPFILES= testecho.cpp
NUMBER_OF_MASTERS =0

VARIANT?=1
CONNECTALFLAGS += -P mkBounce --floorplan=floorplan.xdc -DRedefInstance=Bounce$(VARIANT)

partial.%:
	VARIANT=2 BOARD=$* make verilog.variant2
	make -C variant2 synth.mkBounce
	make verilog.$*
	make -C $* synth.mkBounce synth.mkZynqTop
	vivado -mode batch -source reconf.tcl

include $(CONNECTALDIR)/Makefile.connectal

