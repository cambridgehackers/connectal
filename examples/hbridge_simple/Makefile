CONNECTALDIR ?= ../..
S2H_INTERFACES = HBridgeCtrlRequest:HBridgeController.req
H2S_INTERFACES = HBridgeController:HBridgeCtrlIndication

ZBLD = $(CONNECTALDIR)/lib/zedboard_robot/bsv
BSVFILES = $(ZBLD)/HBridgeController.bsv
CPPFILES= test_hbridge.cpp

PIN_TYPE = HBridgeSimplePins
PIN_TYPE_INCLUDE = HBridgeController
PINOUT_FILE = pinout.json
PIN_BINDINGS = pmod:pmodc
AUTOTOP = --interface pins:HBridgeController.pins

include $(CONNECTALDIR)/Makefile.connectal
