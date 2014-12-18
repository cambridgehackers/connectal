
CONNECTALDIR?=../..
INTERFACES = Simple ZynqPcieTestIndication ZynqPcieTestRequest
BSVFILES = SimpleIF.bsv ZynqPcieTestIF.bsv Top.bsv
CPPFILES=testzynqpcie.cpp
NUMBER_OF_MASTERS =0
PIN_TYPE=ZynqPcie
CONNECTALFLAGS += -D PcieHostIF=1 -D PCIE_NO_BSCAN=1 --bscflags="+RTS -K96000000 -RTS"
CONNECTALFLAGS += --xci=$(CONNECTALDIR)/out/$(BOARD)/pcie_7x_0/pcie_7x_0.xci -C $(BOARD)/sources/zynqpcie.xdc
CONNECTALFLAGS += -P mkPcieHostTopSynth -P mkMemSlaveEngine

## this design would work on a Virtex board with a second PCIE port
PIN_BINDINGS ?= -b pcie:pcie

gentarget:: $(BOARD)/sources/zynqpcie.xdc

prebuild:: synth-ip.tcl
	(cd $(BOARD); vivado -mode batch -source ../synth-ip.tcl)

$(BOARD)/sources/zynqpcie.xdc: zynqpcie.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
	$(CONNECTALDIR)/scripts/generate-constraints.py $(PIN_BINDINGS) $(CONNECTALDIR)/boardinfo/$(BOARD).json zynqpcie.json > $(BOARD)/sources/zynqpcie.xdc


include $(CONNECTALDIR)/Makefile.connectal
