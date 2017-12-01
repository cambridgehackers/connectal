CONNECTALDIR?=../..
S2H_INTERFACES = Ddr3TestRequest:Ddr3Test.request
H2S_INTERFACES = Ddr3Test:Ddr3TestIndication:host

ifneq ($(BOARD),zc706)
ifneq ($(BOARD),miniitx100)
CONNECTALFLAGS += -D DataBusWidth=128
endif
endif
CONNECTALFLAGS += -D IMPORT_HOSTIF -D XILINX_SYS_CLK
CONNECTALFLAGS += --xci=$(IPDIR)/$(BOARD)/axiddr3/axiddr3.xci

BSVFILES = Ddr3Test.bsv
CPPFILES=testddr3.cpp

PIN_TYPE = Ddr3Pins
PIN_TYPE_INCLUDE = AxiDdr3Controller
AUTOTOP = --interface pins:Ddr3Test.ddr3

include $(CONNECTALDIR)/Makefile.connectal
