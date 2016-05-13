CONNECTALDIR?=../..

S2H_INTERFACES = RootPortRequest:RootPort.request
H2S_INTERFACES = RootPort:RootPortIndication:host

BSVFILES = RootPortIfc.bsv
CPPFILES= rootport.cpp

PINOUT_FILE += rootport.json
PIN_TYPE = RootPortPins
PIN_TYPE_INCLUDE = RootPortPins
AUTOTOP = --interface pins:RootPort.pins

AUTOTOP += --portalclock=lRootPort.portalClockSource
CONNECTALFLAGS += -D TOP_SOURCES_PORTAL_CLOCK --mainclockperiod=8

CONNECTALFLAGS += -D IMPORT_HOSTIF
CONNECTALFLAGS += --xci=$(BOARD)/cores/$(BOARD)/axi_pcie_rp/axi_pcie_rp.xci

include $(CONNECTALDIR)/Makefile.connectal
