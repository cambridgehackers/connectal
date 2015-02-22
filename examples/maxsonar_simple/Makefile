
CONNECTALDIR ?= ../..
INTERFACES = MaxSonarCtrlRequest MaxSonarCtrlIndication
BSVFILES = MaxSonarController.bsv Top.bsv 
CPPFILES= test_maxsonar.cpp
NUMBER_OF_MASTERS =0
PIN_TYPE = MaxSonarPins
CONNECTALFLAGS = -C $(BOARD)/sources/pinout-$(BOARD).xdc

PIN_BINDING ?= -b pmod:pmodb

gentarget:: $(BOARD)/sources/pinout-$(BOARD).xdc
$(BOARD)/sources/pinout-$(BOARD).xdc: pinout.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
	$(CONNECTALDIR)/scripts/generate-constraints.py $(PIN_BINDING) -o $(BOARD)/sources/pinout-$(BOARD).xdc $(CONNECTALDIR)/boardinfo/$(BOARD).json pinout.json

include $(CONNECTALDIR)/Makefile.connectal
