CONNECTALDIR?=../..

S2H_INTERFACES = NvmeRequest:Nvme.request NvmeDriverRequest:Nvme.driverRequest MemServerPortalRequest:Nvme.bramRequest
H2S_INTERFACES = Nvme:NvmeIndication,NvmeDriverIndication,NvmeTrace,MemServerPortalIndication

MEM_READ_INTERFACES = lNvme.dmaReadClient
MEM_WRITE_INTERFACES = lNvme.dmaWriteClient

BSVPATH = $(CONNECTALDIR)/lib/strstr/bsv
BSVFILES = NvmeIfc.bsv $(CONNECTALDIR)/bsv/ConnectalConfig.bsv
CPPFILES += nvme.cpp
CPPFILES += $(CONNECTALDIR)/cpp/DmaBuffer.cpp

ifeq ($(BOARD),miniitx100)
PINOUT_FILE += nvme.json
CONNECTALFLAGS += -D PcieDataBusWidth=128
else
#PINOUT_FILE += nfsume.json
CONNECTALFLAGS += -D PcieDataBusWidth=256
endif
CONNECTALFLAGS += -D BlocksPerRequest=8
PIN_TYPE = NvmePins
PIN_TYPE_INCLUDE = NvmePins
AUTOTOP = --interface pins:Nvme.pins

AUTOTOP += --portalclock=lNvme.portalClockSource
CONNECTALFLAGS += --cxxflags=-std=c++11
CONNECTALFLAGS += -D USE_ACP
CONNECTALFLAGS += -D TOP_SOURCES_PORTAL_CLOCK --mainclockperiod=8
CONNECTALFLAGS += --stl=c++_static

CONNECTALFLAGS += -I $(CONNECTALDIR)/lib/strstr/cpp
CONNECTALFLAGS += --bsvpath=../spikehw
CONNECTALFLAGS += --xci=cores/$(BOARD)/axi_pcie_rp/axi_pcie_rp.xci
CONNECTALFLAGS += --implconstraint=nvme.xdc

include $(CONNECTALDIR)/Makefile.connectal
