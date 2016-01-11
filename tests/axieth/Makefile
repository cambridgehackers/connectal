CONNECTALDIR?=../..
S2H_INTERFACES = AxiEthTestRequest:AxiEth.request
H2S_INTERFACES = AxiEth:AxiEthTestIndication:host
#MEM_READ_INTERFACES = lAxiEth.dmaReadClient
#MEM_WRITE_INTERFACES = lAxiEth.dmaWriteClient

CONNECTALFLAGS+= -P mkConnectalTop
#CONNECTALFLAGS+= --shared


BSVFILES = AxiEth.bsv
CPPFILES=testaxieth.cpp

CONNECTALFLAGS+= -DDataBusWidth=32
## ethernet uses the 200MHz SYS clock
CONNECTALFLAGS += -DXILINX_SYS_CLK -D IMPORT_HOSTIF
CONNECTALFLAGS+= --xci=$(IPDIR)/$(BOARD)/axi_dma_0/axi_dma_0.xci
CONNECTALFLAGS+= --xci=$(IPDIR)/$(BOARD)/axi_ethernet_0/axi_ethernet_0.xci

ifeq ($(BOARD),vc709)
PINOUT_FILE += axieth.json
PIN_TYPE = AxiEthPins
PIN_TYPE_INCLUDE = EthPins
AUTOTOP = --interface pins:AxiEth.pins
endif

include $(CONNECTALDIR)/Makefile.connectal
