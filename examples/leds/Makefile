
CONNECTALDIR?=../..
S2H_INTERFACES = LedControllerRequest:LedController.request
BSVFILES = LedController.bsv
CPPFILES= testleds.cpp
NUMBER_OF_MASTERS =0

PIN_TYPE = LedPins
PINOUT_FILE = pinout.json
AUTOTOP = --interface pins:LedController.leds --importfiles LedController

include $(CONNECTALDIR)/Makefile.connectal
