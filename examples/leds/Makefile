CONNECTALDIR?=../..
S2H_INTERFACES = LedControllerRequest:LedController.request

BSVFILES = LedController.bsv
CPPFILES= testleds.cpp

PIN_TYPE = LedPins
PIN_TYPE_INCLUDE = LedController
PINOUT_FILE = pinout.json
AUTOTOP = --interface pins:LedController.leds

include $(CONNECTALDIR)/Makefile.connectal
