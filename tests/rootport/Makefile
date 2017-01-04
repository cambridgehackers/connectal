CONNECTALDIR?=../..

S2H_INTERFACES = RootPortRequest:RootPort.request
H2S_INTERFACES = RootPort:RootPortIndication,RootPortTrace:host

MEM_READ_INTERFACES = lRootPort.dmaReadClient
MEM_WRITE_INTERFACES = lRootPort.dmaWriteClient

BSVFILES = RootPortIfc.bsv $(CONNECTALDIR)/bsv/ConnectalConfig.bsv
CPPFILES= rootport.cpp

PINOUT_FILE += rootport.json
PIN_TYPE = RootPortPins
PIN_TYPE_INCLUDE = RootPortPins
AUTOTOP = --interface pins:RootPort.pins

AUTOTOP += --portalclock=lRootPort.portalClockSource
CONNECTALFLAGS += -D USE_ACP
CONNECTALFLAGS += -D TOP_SOURCES_PORTAL_CLOCK --mainclockperiod=8

CONNECTALFLAGS += -D IMPORT_HOSTIF --bsvpath=../spikehw
CONNECTALFLAGS += --xci=cores/$(BOARD)/axi_pcie_rp/axi_pcie_rp.xci
CONNECTALFLAGS += --implconstraint=rootport.xdc

include $(CONNECTALDIR)/Makefile.connectal
