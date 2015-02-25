
CONNECTALDIR ?= ../..
ZBLD = $(CONNECTALDIR)/lib/zedboard_robot/bsv
INTERFACES = MaxSonarCtrlRequest MaxSonarCtrlIndication
BSVFILES = $(ZBLD)/MaxSonarController.bsv Top.bsv 
CPPFILES= test_maxsonar.cpp $(CONNECTALDIR)/cpp/sock_server.cpp
NUMBER_OF_MASTERS =1
CONNECTALFLAGS = -C $(BOARD)/sources/pinout-$(BOARD).xdc

PIN_TYPE = MaxSonarPins
PIN_BINDING ?= -b pmod:pmodb

gentarget:: $(BOARD)/sources/pinout-$(BOARD).xdc
$(BOARD)/sources/pinout-$(BOARD).xdc: pinout.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
	$(CONNECTALDIR)/scripts/generate-constraints.py $(PIN_BINDING) -o $(BOARD)/sources/pinout-$(BOARD).xdc $(CONNECTALDIR)/boardinfo/$(BOARD).json pinout.json

include $(CONNECTALDIR)/Makefile.connectal
