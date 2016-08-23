CONNECTALDIR?=../..

S2H_INTERFACES = NvmeRequest:NvmeSearch.request NvmeDriverRequest:NvmeSearch.driverRequest MemServerPortalRequest:NvmeSearch.bramRequest StringSearchRequest:NvmeSearch.searchRequest
H2S_INTERFACES = NvmeSearch:NvmeIndication,NvmeDriverIndication,NvmeTrace,MemServerPortalIndication,StringSearchResponse

MEM_READ_INTERFACES = lNvmeSearch.dmaReadClient
MEM_WRITE_INTERFACES = lNvmeSearch.dmaWriteClient

BSVPATH = $(CONNECTALDIR)/lib/strstr/bsv
BSVFILES = $(CONNECTALDIR)/lib/nvme/bsv/NvmeIfc.bsv StringSearchIfc.bsv $(CONNECTALDIR)/bsv/ConnectalConfig.bsv
CPPFILES += $(CONNECTALDIR)/lib/nvme/cpp/nvme.cpp main.cpp
CPPFILES += $(CONNECTALDIR)/cpp/DmaBuffer.cpp

CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/nvme/cpp

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
AUTOTOP = --interface pins:NvmeSearch.pins

AUTOTOP += --portalclock=lNvmeSearch.portalClockSource
CONNECTALFLAGS += --cxxflags=-std=c++11
CONNECTALFLAGS += -D USE_ACP
CONNECTALFLAGS += -D TOP_SOURCES_PORTAL_CLOCK --mainclockperiod=8
CONNECTALFLAGS += --stl=c++_static

CONNECTALFLAGS += -I $(CONNECTALDIR)/lib/strstr/cpp
CONNECTALFLAGS += --bsvpath=../spikehw
CONNECTALFLAGS += --xci=cores/$(BOARD)/axi_pcie_rp/axi_pcie_rp.xci
CONNECTALFLAGS += --implconstraint=nvme.xdc

CONNECTALFLAGS += -DNVME_ACCELERATOR_INTERFACE=1

include $(CONNECTALDIR)/Makefile.connectal
