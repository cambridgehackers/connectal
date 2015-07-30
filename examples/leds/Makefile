
CONNECTALDIR?=../..
S2H_INTERFACES = LedControllerRequest:LedController.request
BSVFILES = LedController.bsv
CPPFILES= testleds.cpp
NUMBER_OF_MASTERS =0

PIN_TYPE = LedPins
PIN_TYPE_INCLUDE = LedController
PINOUT_FILE = pinout.json
AUTOTOP = --interface pins:LedController.leds

include $(CONNECTALDIR)/Makefile.connectal
