CONNECTALDIR?=../..
S2H_INTERFACES = BpiFlashTestRequest:BpiFlashTest.request
H2S_INTERFACES = BpiFlashTest:BpiFlashTestIndication

CONNECTALFLAGS += --verilog=i28f512p33.v -I$(realpath .) --mainclockperiod=100

BSVFILES = BpiFlashTest.bsv
CPPFILES=testbpiflash.cpp

ifeq ($(BOARD),vc709)
PIN_TYPE = BpiPins
PIN_TYPE_INCLUDE = BpiFlash
AUTOTOP = --interface pins:BpiFlashTest.pins
endif

include $(CONNECTALDIR)/Makefile.connectal
