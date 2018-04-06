CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:TracePcie.request ChangeRequest:TracePcie.changeRequest
H2S_INTERFACES = TracePcie:ChangeIndication:host TracePcie:EchoIndication 

BSVFILES = TracePcie.bsv
CPPFILES= tracepcie.cpp

CONNECTALFLAGS += -D TRACE_PORTAL

CONNECTALFLAGS += -D IMPORT_HOSTIF -D PCIE_CHANGES_HOSTIF -D TracePcieStateMachine
CONNECTALFLAGS += -D PCIE_CHANGES_SERIAL 
CONNECTALFLAGS += -D PCIE_CHANGES_UART
CONNECTALFLAGS += -D PCIE_ALT_BRAM_SERVER -D PCIE_TRACE_PORT
PINOUT_FILE += pin_translation.json
PIN_TYPE = TestPins
PIN_TYPE_INCLUDE = TestPins
AUTOTOP = --interface pins:TracePcie.pins

include $(CONNECTALDIR)/Makefile.connectal

