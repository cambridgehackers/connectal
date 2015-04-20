
CONNECTALDIR?=../..
S2H_INTERFACES = Ov7670ControllerRequest:Ov7670Controller.request
H2S_INTERFACES = Ov7670Controller:Ov7670ControllerIndication
BSVFILES = Ov7670Interface.bsv
CPPFILES= testcam.cpp
NUMBER_OF_MASTERS =0

PIN_TYPE = Ov7670Pins
PINOUT_FILE = pinout.json
AUTOTOP = --interface pins:Ov7670Controller.pins --importfiles Ov7670Interface

include $(CONNECTALDIR)/Makefile.connectal
