
CONNECTALDIR?=../..
S2H_INTERFACES = LedControllerRequest:LedController.request
BSVFILES = LedController.bsv
CPPFILES= testleds.cpp
NUMBER_OF_MASTERS =0
PIN_TYPE = LEDS
PIN_BINDING ?= -b leds:leds
CONNECTALFLAGS += -C $(BOARD)/sources/pinout-$(BOARD).xdc

AUTOTOP = --interface pins:LedController.leds --importfiles Leds

gentarget:: $(BOARD)/sources/pinout-$(BOARD).xdc
$(BOARD)/sources/pinout-$(BOARD).xdc: pinout.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
	$(CONNECTALDIR)/scripts/generate-constraints.py $(PIN_BINDING) -o $(BOARD)/sources/pinout-$(BOARD).xdc $(CONNECTALDIR)/boardinfo/$(BOARD).json pinout.json


include $(CONNECTALDIR)/Makefile.connectal
