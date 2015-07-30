
CONNECTALDIR ?= ../..
S2H_INTERFACES = STestRequest:STest.request
H2S_INTERFACES = STest:STestIndication
BSVFILES = STest.bsv
CPPFILES = testspi.cpp
NUMBER_OF_MASTERS = 0

PIN_TYPE = STestPins
PIN_TYPE_INCLUDE = STest
PINOUT_FILE = pinout.json
PIN_BINDINGS = pmod:pmodd

AUTOTOP = --interface pins:STest.pins

include $(CONNECTALDIR)/Makefile.connectal
