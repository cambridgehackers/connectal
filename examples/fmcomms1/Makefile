
CONNECTALDIR?=../..
INTERFACES = FMComms1Request FMComms1Indication \
	BlueScopeEventPIORequest  BlueScopeEventPIOIndication
BSVFILES = ../../lib/bsv/BlueScopeEventPIO.bsv \
	FMComms1ADC.bsv FMComms1DAC.bsv FMComms1.bsv \
	 Top.bsv
CPPFILES=testfmcomms1.cpp fmci2c.c i2c_zedboardandroid.c
CONNECTALFLAGS = -C fmcomms1-$(BOARD).xdc --tcl clock.tcl
CONNECTALFLAGS +=  -D USE_FMC_I2C1 -D IMPORT_HOSTIF
PIN_TYPE = FMComms1Pins

ifeq ($(BOARD),zedboard)
HAS_PS7=true
CONNECTALFLAGS += -D USE_I2C0
endif
ifeq ($(BOARD),zc702)
HAS_PS7=true
endif

PIN_BINDINGS ?= -b fmc:fmc1

gentarget:: fmcomms1-$(BOARD).xdc

fmcomms1-$(BOARD).xdc: fmcomms1-fmc.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
	$(CONNECTALDIR)/scripts/generate-constraints.py $(PIN_BINDINGS) -o fmcomms1-$(BOARD).xdc $(CONNECTALDIR)/boardinfo/$(BOARD).json fmcomms1-fmc.json


include $(CONNECTALDIR)/Makefile.connectal

