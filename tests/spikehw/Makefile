CONNECTALDIR?=../..
S2H_INTERFACES = SpikeHwRequest:SpikeHw.request
H2S_INTERFACES = SpikeHw:SpikeHwIndication:host

MEM_READ_INTERFACES = lSpikeHw.dmaReadClient
MEM_WRITE_INTERFACES = lSpikeHw.dmaWriteClient

CONNECTALFLAGS+= -P mkConnectalTop
CONNECTALFLAGS+= --shared


BSVFILES =  SpikeHw.bsv
CPPFILES= spikehw.cpp

ifneq ($(BOARD),vc709)
CONNECTALFLAGS+= --verilog=i28f512p33.v
endif

ifneq ($(BOARD),xsim)
PINOUT_FILE += spikehw.json
PINOUT_FILE += spikehw-$(BOARD).json
endif
PIN_TYPE = SpikeHwPins
PIN_TYPE_INCLUDE = SpikeHwPins
AUTOTOP = --interface pins:SpikeHw.pins

CONNECTALFLAGS+= -DDataBusWidth=32
## ethernet uses the 200MHz SYS clock
CONNECTALFLAGS += -D XILINX_SYS_CLK -D IMPORT_HOSTIF
CONNECTALFLAGS+= --xci=$(IPDIR)/$(BOARD)/axi_intc_0/axi_intc_0.xci
CONNECTALFLAGS+= --xci=$(IPDIR)/$(BOARD)/axi_dma_0/axi_dma_0.xci
CONNECTALFLAGS+= --xci=$(IPDIR)/$(BOARD)/axi_ethernet_0/axi_ethernet_0.xci
CONNECTALFLAGS += --constraint=spikehw.xdc --implconstraint=spikehw.xdc

test-spikehw.o: test-spikehw.cpp spikehw.h
	g++ -g -O -pthread -c -I. test-spikehw.cpp

test-spikehw.%: test-spikehw.o
	$(MAKE) -C $(*) connectal.so
	g++ -g -O -pthread -o test-spikehw.$(*) test-spikehw.o $(*)/bin/connectal.so -lc 

include $(CONNECTALDIR)/Makefile.connectal
