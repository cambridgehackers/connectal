
CONNECTALDIR ?= ../..
ZBLD = $(CONNECTALDIR)/lib/zedboard_robot/bsv
INTERFACES = SDIORequest SDIOIndication
BSVFILES = Top.bsv SDIO.bsv
CPPFILES= test_sdio1.cpp
NUMBER_OF_MASTERS =0

PIN_TYPE = TestSDIO1Pins
PINOUT_FILE = pinout.json
PIN_BINDINGS = pmod:pmoda

include $(CONNECTALDIR)/Makefile.connectal
