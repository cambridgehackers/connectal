CONNECTALDIR ?= ../..
S2H_INTERFACES = HBridgeCtrlRequest:HBridgeController.req
H2S_INTERFACES = HBridgeController:HBridgeCtrlIndication

ZBLD = $(CONNECTALDIR)/lib/zedboard_robot/bsv
BSVFILES = $(ZBLD)/HBridgeController.bsv
CPPFILES= test_hbridge.cpp
NUMBER_OF_MASTERS =0

PIN_TYPE = HBridgeSimplePins
PINOUT_FILE = pinout.json
PIN_BINDINGS = pmod:pmodc
AUTOTOP = --interface pins:HBridgeController.pins --importfiles HBridgeController

include $(CONNECTALDIR)/Makefile.connectal
