
S2H = ImageonSerdesRequest    ImageonSensorRequest    HdmiInternalRequest
H2S = ImageonSerdesIndication ImageonSensorIndication HdmiInternalIndication
BSVFILES = $(XBSVDIR)/lib/bsv/IserdesDatadeser.bsv $(XBSVDIR)/lib/bsv/HDMI.bsv $(XBSVDIR)/lib/bsv/Imageon.bsv Top.bsv
CPPFILES=testimagecapture.cpp
XBSVFLAGS = -C $(BOARD)/sources/imageon-$(BOARD).xdc --tcl clock.tcl
XBSVFLAGS += --bscflags " -D NumberOfMasters=0"
#XBSVFLAGS += --bscflags " -D TRACE_AXI"
XBSVFLAGS += --bscflags " -D USE_I2C1 -D PinType=ImageCapturePins"

ifeq ($(BOARD),zedboard)
HAS_PS7=true
XBSVFLAGS += -D USE_I2C0
endif
ifeq ($(BOARD),zc702)
HAS_PS7=true
endif

ifneq ($(HAS_PS7),true)
TOP=ImageonPcieTop.bsv
MKTOP=mkImageonPcieTop
endif

gentarget:: $(BOARD)/sources/imageon-$(BOARD).xdc

$(BOARD)/sources/imageon-$(BOARD).xdc: imageon-fmc.json ../../boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
	../../scripts/generate-constraints.py ../../boardinfo/$(BOARD).json imageon-fmc.json > $(BOARD)/sources/imageon-$(BOARD).xdc

include ../../Makefile.common

