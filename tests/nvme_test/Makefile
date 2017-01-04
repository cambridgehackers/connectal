CONNECTALDIR?=../..

S2H_INTERFACES = NvmeRequest:NvmeTest.request NvmeDriverRequest:NvmeTest.driverRequest MemServerPortalRequest:NvmeTest.bramRequest
H2S_INTERFACES = NvmeTest:NvmeIndication,NvmeDriverIndication,NvmeTrace,MemServerPortalIndication

MEM_READ_INTERFACES = lNvmeTest.dmaReadClient
MEM_WRITE_INTERFACES = lNvmeTest.dmaWriteClient

BSVPATH = $(CONNECTALDIR)/lib/strstr/bsv
BSVFILES = $(CONNECTALDIR)/lib/nvme/bsv/NvmeIfc.bsv $(CONNECTALDIR)/bsv/ConnectalConfig.bsv
CPPFILES += $(CONNECTALDIR)/lib/nvme/cpp/nvme.cpp main.cpp
CPPFILES += $(CONNECTALDIR)/cpp/DmaBuffer.cpp

CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/nvme/cpp

CONNECTALFLAGS += -DTRACE_PORTAL

ifeq ($(BOARD),miniitx100)
PINOUT_FILE += nvme.json
CONNECTALFLAGS += -D PcieDataBusWidth=128
CONNECTALFLAGS += -D USE_ACP
CONNECTALFLAGS += -D TOP_SOURCES_PORTAL_CLOCK
CONNECTALFLAGS +=  --mainclockperiod=8
else
ifeq ($(BOARD),kc705g2)
CONNECTALFLAGS += --pin-binding FMC:fmc1
endif
ifeq ($(BOARD),nfsume)
CONNECTALFLAGS += --implconstraint=nfsume.xdc
endif
#PINOUT_FILE += fmc.json
CONNECTALFLAGS += -D PcieDataBusWidth=128
endif
CONNECTALFLAGS += -D BlocksPerRequest=8
PIN_TYPE = NvmePins
PIN_TYPE_INCLUDE = NvmePins
AUTOTOP = --interface pins:NvmeTest.pins

AUTOTOP += --portalclock=lNvmeTest.portalClockSource
CONNECTALFLAGS += --cxxflags=-std=c++11
CONNECTALFLAGS += --stl=c++_static

CONNECTALFLAGS += -I $(CONNECTALDIR)/lib/strstr/cpp
CONNECTALFLAGS += --bsvpath=../spikehw
CONNECTALFLAGS += --xci=$(IPDIR)/$(BOARD)/axi_pcie_rp/axi_pcie_rp.xci
CONNECTALFLAGS += -D GET_PUT_WITH_CLOCKS_USE_XILINX_FIFO
CONNECTALFLAGS += --xci=$(IPDIR)/$(BOARD)/dual_clock_axis_fifo_32x8/dual_clock_axis_fifo_32x8.xci
CONNECTALFLAGS += --implconstraint=nvme.xdc

#CONNECTALFLAGS += -DNVME_ACCELERATOR_INTERFACE=1

include $(CONNECTALDIR)/Makefile.connectal
