CONNECTALDIR?=../..
S2H_INTERFACES = Ov7670ControllerRequest:Ov7670Controller.request
H2S_INTERFACES = Ov7670Controller:Ov7670ControllerIndication
MEM_WRITE_INTERFACES = lOv7670Controller.dmaClient

BSVFILES = Ov7670Interface.bsv
CPPFILES= testcam.cpp

PIN_TYPE = Ov7670Pins
PIN_TYPE_INCLUDE = Ov7670Interface
PINOUT_FILE = pinout.json
AUTOTOP = --interface pins:Ov7670Controller.pins

include $(CONNECTALDIR)/Makefile.connectal
