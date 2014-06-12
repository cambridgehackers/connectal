
S2H = ImageonSerdesRequest    ImageonSensorRequest    HdmiInternalRequest
H2S = ImageonSerdesIndication ImageonSensorIndication HdmiInternalIndication
BSVFILES = $(XBSVDIR)/lib/bsv/IserdesDatadeser.bsv $(XBSVDIR)/lib/bsv/HDMI.bsv $(XBSVDIR)/lib/bsv/Imageon.bsv Top.bsv
CPPFILES=testimagecapture.cpp
XBSVFLAGS = -C $(BOARD)/sources/imageon-$(BOARD).xdc --tcl clock.tcl
XBSVFLAGS += -D NumberOfMasters=0 -D USE_I2C1 -D PinType=ImageCapturePins
#XBSVFLAGS += -D TRACE_AXI

ifeq ($(BOARD),zedboard)
  XBSVFLAGS += -D USE_I2C0
else
  ifneq ($(BOARD),zc702)
    TOP=ImageonPcieTop.bsv
    MKTOP=mkImageonPcieTop
  endif
endif

gentarget:: $(BOARD)/sources/imageon-$(BOARD).xdc

$(BOARD)/sources/imageon-$(BOARD).xdc: imageon-fmc.json ../../boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
	../../scripts/generate-constraints.py ../../boardinfo/$(BOARD).json imageon-fmc.json > $(BOARD)/sources/imageon-$(BOARD).xdc

include ../../Makefile.common

