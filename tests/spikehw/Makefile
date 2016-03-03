
INCLUDE_ETHERNET=0

SPIKE_DIR=/home/jamey/riscv-isa-sim
CONNECTALDIR?=../..

S2H_INTERFACES = SpikeHwRequest:SpikeHw.request
H2S_INTERFACES = SpikeHw:SpikeHwIndication:host

MEM_READ_INTERFACES = lSpikeHw.dmaReadClient
MEM_WRITE_INTERFACES = lSpikeHw.dmaWriteClient

CONNECTALFLAGS+= -P mkConnectalTop
CONNECTALFLAGS+= --shared
CONNECTALFLAGS += --derivedclockperiod=67.81684027

RISCV_INCLUDES = -I$(SPIKE_DIR) -I$(SPIKE_DIR)/build
CONNECTALFLAGS += $(RISCV_INCLUDES) --cxxflags=-std=c++11 --cflags=-std=c++11

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
IPDIR=cores
CONNECTALFLAGS+= --xci=$(IPDIR)/$(BOARD)/axi_intc_0/axi_intc_0.xci
CONNECTALFLAGS+= --xci=$(IPDIR)/$(BOARD)/axi_iic_0/axi_iic_0.xci
CONNECTALFLAGS+= --xci=$(IPDIR)/$(BOARD)/axi_uart16550_1/axi_uart16550_1.xci
CONNECTALFLAGS+= --xci=$(IPDIR)/$(BOARD)/axi_dma_0/axi_dma_0.xci

CONNECTALFLAGS += --constraint=spikehw.xdc --implconstraint=spikehw.xdc

##PREBUILD_DEPS = $(IPDIR)/$(BOARD)/axi_dma_0/axi_dma_0.xci $(IPDIR)/$(BOARD)/axi_intc_0/axi_intc_0.xci

ifeq ($(INCLUDE_ETHERNET),1)
CONNECTALFLAGS+= --xci=$(IPDIR)/$(BOARD)/axi_ethernet_0.xci
CONNECTALFLAGS+= -D IncludeEthernet
##PREBUILD_DEPS += $(IPDIR)/$(BOARD)/axi_ethernet_0/axi_ethernet_0.xci
endif

prebuild:: $(PREBUILD_DEPS)
	ln -sf $(PWD)/bootromx4.hex $(BOARD)

$(IPDIR)/$(BOARD)/axi_intc_0/axi_intc_0.xci: ../../scripts/connectal-synth-axidma.tcl
	cd $(BOARD); vivado -mode batch -source $(CONNECTALDIR)/scripts/connectal-synth-axiintc.tcl

$(IPDIR)/$(BOARD)/axi_ethernet_0/axi_ethernet_0.xci: ../../scripts/connectal-synth-axieth.tcl
	cd $(BOARD); vivado -mode batch -source $(CONNECTALDIR)/scripts/connectal-synth-axieth.tcl

$(IPDIR)/$(BOARD)/axi_dma_0/axi_dma_0.xci: ../../scripts/connectal-synth-axidma.tcl
	cd $(BOARD); vivado -mode batch -source $(CONNECTALDIR)/scripts/connectal-synth-axidma.tcl

test-spikehw.o: test-spikehw.cpp spikehw.h
	g++ $(RISCV_INCLUDES) -std=c++11 -g -O -pthread -c -I. test-spikehw.cpp

test-spikehw.%: test-spikehw.o
	#$(MAKE) build.$(*)
	g++ $(RISCV_INCLUDES) -g -O -pthread -o test-spikehw.$(*) test-spikehw.o $(*)/bin/connectal.so -lc 

include $(CONNECTALDIR)/Makefile.connectal

