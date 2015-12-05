CONNECTALDIR?=../..
S2H_INTERFACES = Ddr3TestRequest:Ddr3Test.request
H2S_INTERFACES = Ddr3Test:Ddr3TestIndication:host
MEM_READ_INTERFACES = lDdr3Test.readClient

ifneq ($(BOARD),zc706)
CONNECTALFLAGS += -D DataBusWidth=128
endif
CONNECTALFLAGS += -D IMPORT_HOSTIF -D XILINX_SYS_CLK
CONNECTALFLAGS += --xci=$(IPDIR)/$(BOARD)/synthesis/altera_mem_if_ddr3_emif_wrapper/altera_mem_if_ddr3_emif_wrapper.qip

BSVFILES = Ddr3Test.bsv
CPPFILES=testddr3.cpp

PIN_BINDINGS ?= DDR3B:DDR3B PCIE:PCIE OSC:OSC RZQ:RZQ
PINOUT_FILE = de5.json

PIN_TYPE = Ddr3Pins
PIN_TYPE_INCLUDE = AvalonDdr3Controller
AUTOTOP = --interface pins:Ddr3Test.pins

prebuild::
	(cd $(BOARD); BUILDCACHE_CACHEDIR=$(BUILDCACHE_CACHEDIR) $(BUILDCACHE) $(QUARTUS_SH) -t $(CONNECTALDIR)/scripts/connectal-synth-avalonddr3.tcl)

include $(CONNECTALDIR)/Makefile.connectal
