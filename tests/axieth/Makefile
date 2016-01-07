CONNECTALDIR?=../..
S2H_INTERFACES = AxiEthTestRequest:AxiEth.request
H2S_INTERFACES = AxiEth:AxiEthTestIndication
MEM_READ_INTERFACES = lAxiEth.dmaReadClient
MEM_WRITE_INTERFACES = lAxiEth.dmaWriteClient

CONNECTALFLAGS+= -P mkConnectalTop
#CONNECTALFLAGS+= --shared


BSVFILES = AxiEth.bsv
CPPFILES=testaxieth.cpp

ifneq ($(BOARD),vc709)
CONNECTALFLAGS+= 
endif

ifeq ($(BOARD),vc709)
PINOUT_FILE += axieth.json
PIN_TYPE = AxiEthPins
PIN_TYPE_INCLUDE = EthPins
AUTOTOP = --interface pins:AxiEth.pins
endif

include $(CONNECTALDIR)/Makefile.connectal
