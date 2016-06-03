CONNECTALDIR?=../..

S2H_INTERFACES = NvmeRequest:Nvme.request MemServerPortalRequest:Nvme.bramRequest
H2S_INTERFACES = Nvme:NvmeIndication,NvmeTrace,MemServerPortalIndication

MEM_READ_INTERFACES = lNvme.dmaReadClient
MEM_WRITE_INTERFACES = lNvme.dmaWriteClient

BSVPATH = $(CONNECTALDIR)/lib/strstr/bsv
BSVFILES = NvmeIfc.bsv $(CONNECTALDIR)/bsv/ConnectalConfig.bsv
CPPFILES= nvme.cpp

PINOUT_FILE += nvme.json
PIN_TYPE = NvmePins
PIN_TYPE_INCLUDE = NvmePins
AUTOTOP = --interface pins:Nvme.pins

AUTOTOP += --portalclock=lNvme.portalClockSource
#CONNECTALFLAGS += -D USE_ACP
CONNECTALFLAGS += -D TOP_SOURCES_PORTAL_CLOCK --mainclockperiod=8

CONNECTALFLAGS += --bsvpath=../spikehw
CONNECTALFLAGS += --xci=cores/$(BOARD)/axi_pcie_rp/axi_pcie_rp.xci
CONNECTALFLAGS += --implconstraint=nvme.xdc

include $(CONNECTALDIR)/Makefile.connectal
