
CONNECTALDIR?=../..
INTERFACES = FMComms1Request FMComms1Indication
BSVFILES = FMComms1ADC.bsv FMComms1DAC.bsv FMComms1.bsv \
	 Top.bsv
CPPFILES=testi2c.c
CONNECTALFLAGS = -C fmcomms1-$(BOARD).xdc --tcl clock.tcl
CONNECTALFLAGS +=  -D USE_I2C1 -D IMPORT_HOSTIF -D PinType=FMComms1Pins

ifeq ($(BOARD),zedboard)
HAS_PS7=true
CONNECTALFLAGS += -D USE_I2C0
endif
ifeq ($(BOARD),zc702)
HAS_PS7=true
endif


gentarget:: fmcomms1-$(BOARD).xdc

fmcomms1-$(BOARD).xdc: fmcomms1-fmc.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
	$(CONNECTALDIR)/scripts/generate-constraints.py $(CONNECTALDIR)/boardinfo/$(BOARD).json fmcomms1-fmc.json > fmcomms1-$(BOARD).xdc


include $(CONNECTALDIR)/Makefile.connectal

