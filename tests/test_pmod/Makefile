CONNECTALDIR ?= ../..
INTERFACES = PmodControllerRequest PmodControllerIndication

BSVFILES = Controller.bsv Top.bsv 
CPPFILES= testpmod.cpp
PIN_TYPE = PmodPins
PIN_TYPE_INCLUDE = Controller
CONNECTALFLAGS = -C $(BOARD)/sources/pinout-$(BOARD).xdc

PIN_BINDING ?= -b pmod:pmoda

gentarget:: $(BOARD)/sources/pinout-$(BOARD).xdc
$(BOARD)/sources/pinout-$(BOARD).xdc: pinout.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
	$(CONNECTALDIR)/scripts/generate-constraints.py $(PIN_BINDING) -o $(BOARD)/sources/pinout-$(BOARD).xdc --boardfile $(CONNECTALDIR)/boardinfo/$(BOARD).json --pinoutfile pinout.json

include $(CONNECTALDIR)/Makefile.connectal
