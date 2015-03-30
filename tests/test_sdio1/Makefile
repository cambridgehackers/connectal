
CONNECTALDIR ?= ../..
ZBLD = $(CONNECTALDIR)/lib/zedboard_robot/bsv
INTERFACES = SDIORequest SDIOResponse
BSVFILES = Top.bsv SDIO.bsv
CPPFILES= test_sdio1.cpp
NUMBER_OF_MASTERS =0
CONNECTALFLAGS += -D PS7EXTENDED -D IMPORT_HOSTIF

PIN_TYPE = TestSDIO1Pins
PINOUT_FILE = pinout.json
PIN_BINDINGS = pmod:pmoda

include $(CONNECTALDIR)/Makefile.connectal
