
CONNECTALDIR ?= ../..
INTERFACES = GyroCtrlRequest GyroCtrlIndication
BSVFILES = Controller.bsv Top.bsv
CPPFILES= test_gyro.cpp
NUMBER_OF_MASTERS =0
PIN_TYPE = SpiPins
CONNECTALFLAGS = -C $(BOARD)/sources/pinout-$(BOARD).xdc #--tcl clock.tcl

PIN_BINDING ?= -b pmod:pmodb

gentarget:: $(BOARD)/sources/pinout-$(BOARD).xdc
$(BOARD)/sources/pinout-$(BOARD).xdc: pinout.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
	$(CONNECTALDIR)/scripts/generate-constraints.py $(PIN_BINDING) -o $(BOARD)/sources/pinout-$(BOARD).xdc $(CONNECTALDIR)/boardinfo/$(BOARD).json pinout.json

include $(CONNECTALDIR)/Makefile.connectal
