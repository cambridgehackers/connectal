CONNECTALDIR?=../..
S2H_INTERFACES = BpiFlashTestRequest:BpiFlashTest.request
H2S_INTERFACES = BpiFlashTest:BpiFlashTestIndication

CONNECTALFLAGS+= -P mkConnectalTop
CONNECTALFLAGS+= --shared


BSVFILES = BpiFlashTest.bsv
CPPFILES=testbpiflash.cpp

ifneq ($(BOARD),vc709)
CONNECTALFLAGS+= --verilog=i28f512p33.v
endif

ifeq ($(BOARD),vc709)
PINOUT_FILE += bpiflash.json
PIN_TYPE = BpiPins
PIN_TYPE_INCLUDE = BpiFlash
AUTOTOP = --interface pins:BpiFlashTest.pins
endif

flash.mcs: flash.hex
	vivado -mode batch -source genmcs.tcl

include $(CONNECTALDIR)/Makefile.connectal
