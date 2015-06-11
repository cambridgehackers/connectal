
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
	make -C variant2 fpgamake.mk
	make -C variant2 -f fpgamake.mk Synth/mkBounce/mkBounce-synth.dcp
	make verilog.$*
	make -C $* fpgamake.mk
	make -C $* -f fpgamake.mk Synth/mkBounce/mkBounce-synth.dcp Synth/mkZynqTop/mkZynqTop-synth.dcp
	vivado -mode batch -source reconf.tcl

include $(CONNECTALDIR)/Makefile.connectal

