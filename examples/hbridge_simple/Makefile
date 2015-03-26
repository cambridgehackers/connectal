
CONNECTALDIR ?= ../..
ZBLD = $(CONNECTALDIR)/lib/zedboard_robot/bsv
INTERFACES = HBridgeCtrlRequest HBridgeCtrlIndication
BSVFILES = $(ZBLD)/HBridgeController.bsv Top.bsv 
CPPFILES= test_hbridge.cpp
NUMBER_OF_MASTERS =0

PIN_TYPE = HBridge2Pins
PINOUT_FILE = pinout.json
PIN_BINDINGS = pmod:pmodc

include $(CONNECTALDIR)/Makefile.connectal
