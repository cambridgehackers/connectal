
S2H = ImageonSerdesRequest    ImageonSensorRequest    HdmiInternalRequest
H2S = ImageonSerdesIndication ImageonSensorIndication HdmiInternalIndication
BSVFILES = $(XBSVDIR)/lib/bsv/IserdesDatadeser.bsv $(XBSVDIR)/lib/bsv/HDMI.bsv $(XBSVDIR)/lib/bsv/Imageon.bsv Top.bsv
CPPFILES=testimagecapture.cpp
XBSVFLAGS = -C imageon-$(BOARD).xdc --tcl clock.tcl
Dma = 
PINS = Std
#XBSVFLAGS += --bscflags " -D TRACE_AXI"
XBSVFLAGS += --bscflags " -D USE_I2C -D PinType=ImageCapturePins"

ifeq ($(BOARD),zedboard)
HAS_PS7=true
endif
ifeq ($(BOARD),zc702)
HAS_PS7=true
endif

ifneq ($(HAS_PS7),true)
TOP=ImageonPcieTop.bsv
MKTOP=mkImageonPcieTop
endif

gen:: pregen

pregen: imageon-$(BOARD).xdc

imageon-$(BOARD).xdc: imageon-fmc.json ../../boardinfo/$(BOARD).json
	../../scripts/generate-constraints.py ../../boardinfo/$(BOARD).json imageon-fmc.json > imageon-$(BOARD).xdc

include ../../Makefile.common

