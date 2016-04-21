CONNECTALDIR?=../..
S2H_INTERFACES = SerialPortalRequest:SerialPortalTest.request EchoIndication:SerialPortalTest.echoIndication SimpleRequest:SerialPortalTest.simpleRequest
H2S_INTERFACES = SerialPortalTest:SerialPortalIndication,EchoRequest,SimpleRequest

INTERFACES = EchoRequest EchoIndication

BSVFILES = SerialPortalIfc.bsv $(CONNECTALDIR)/examples/echo/Echo.bsv $(CONNECTALDIR)/examples/simple/Simple.bsv
CPPFILES= serialportal.cpp

CONNECTALFLAGS += -I $(CONNECTALDIR)/examples/simple

PINOUT_FILE += rs232.json
PIN_TYPE = SerialPortalPins
PIN_TYPE_INCLUDE = SerialPortalIfc
AUTOTOP = --interface pins:SerialPortalTest.pins
include $(CONNECTALDIR)/Makefile.connectal
