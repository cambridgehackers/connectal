
CONNECTALDIR ?= ../..
INTERFACES = GyroCtrlRequest GyroCtrlIndication Sample
BSVFILES = Controller.bsv Top.bsv
CPPFILES  = test_sample.cpp
CPPFILES2 = test_gyro.cpp
NUMBER_OF_MASTERS = 1
CONNECTALFLAGS += -C $(BOARD)/sources/pinout-$(BOARD).xdc #--tcl clock.tcl
CONNECTALFLAGS += --shared

PIN_TYPE = SpiPins
PIN_BINDING ?= -b pmod:pmodd

gentarget:: $(BOARD)/sources/pinout-$(BOARD).xdc
$(BOARD)/sources/pinout-$(BOARD).xdc: pinout.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
	$(CONNECTALDIR)/scripts/generate-constraints.py $(PIN_BINDING) -o $(BOARD)/sources/pinout-$(BOARD).xdc $(CONNECTALDIR)/boardinfo/$(BOARD).json pinout.json

include $(CONNECTALDIR)/Makefile.connectal
