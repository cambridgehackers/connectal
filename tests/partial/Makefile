
CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication
BSVFILES = Echo.bsv
CPPFILES= testecho.cpp
NUMBER_OF_MASTERS =0

VARIANT?=1
CONNECTALFLAGS += -P mkBounce --floorplan=floorplan.xdc -DRedefInstance=Bounce$(VARIANT)

partial:
	make gen.zc702
	make -C zc702 verilog fpgamake.mk
	make -C zc702 -f fpgamake.mk Synth/mkBounce1/mkBounce1-synth.dcp Synth/mkZynqTop/mkZynqTop-synth.dcp
	vivado -mode batch -source reconf.tcl

include $(CONNECTALDIR)/Makefile.connectal

