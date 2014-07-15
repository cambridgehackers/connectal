
S2H = FMComms1Request
H2S = FMComms1Indication
BSVFILES = FMComms1ADC.bsv FMComms1DAC.bsv FMComms1.bsv Top.bsv
CPPFILES=testfmcomms1.cpp
XBSVFLAGS = -C fmcomms1-$(BOARD).xdc --tcl clock.tcl
#XBSVFLAGS += --bscflags " -D TRACE_AXI"
XBSVFLAGS += --bscflags " -D USE_I2C1 -D IMPORT_HOSTIF -D PinType=FMComms1Pins"

ifeq ($(BOARD),zedboard)
HAS_PS7=true
XBSVFLAGS += -D USE_I2C0
endif
ifeq ($(BOARD),zc702)
HAS_PS7=true
endif

# fill in someday
ifneq ($(HAS_PS7),true)
TOP=ImageonPcieTop.bsv
MKTOP=mkImageonPcieTop
endif

gentarget:: fmcomms1-$(BOARD).xdc

fmcomms1-$(BOARD).xdc: fmcomms1-fmc.json ../../boardinfo/$(BOARD).json
	../../scripts/generate-constraints.py ../../boardinfo/$(BOARD).json fmcomms1-fmc.json > fmcomms1-$(BOARD).xdc

include ../../Makefile.common

