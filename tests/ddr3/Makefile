CONNECTALDIR?=../..
S2H_INTERFACES = Ddr3TestRequest:Ddr3Test.request
H2S_INTERFACES = Ddr3Test:Ddr3TestIndication:host
#MEM_READ_INTERFACES = lDdr3Test.readClient
MEM_WRITE_INTERFACES = lDdr3Test.writeClient

ifneq ($(BOARD),zc706)
CONNECTALFLAGS += -D DataBusWidth=128
endif
CONNECTALFLAGS += -D IMPORT_HOSTIF -D XILINX_SYS_CLK
CONNECTALFLAGS += --xci=$(IPDIR)/$(BOARD)/axiddr3/axiddr3.xci

BSVFILES = Ddr3Test.bsv
CPPFILES=testddr3.cpp

PIN_TYPE = Ddr3Pins
PIN_TYPE_INCLUDE = AxiDdr3Controller
AUTOTOP = --interface pins:Ddr3Test.ddr3

$(IPDIR)/$(BOARD)/axiddr3/axiddr3.xci: $(CONNECTALDIR)/scripts/connectal-synth-axiddr3.tcl
	cd $(BOARD); vivado -mode batch -source $(CONNECTALDIR)/scripts/connectal-synth-axiddr3.tcl

ip.%:
	make BOARD=$(*) gen.$(*)
	make BOARD=$(*) IPDIR=$(IPDIR) $(IPDIR)/$(*)/axiddr3/axiddr3.xci

include $(CONNECTALDIR)/Makefile.connectal
