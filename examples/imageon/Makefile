
INTERFACES = ImageonSerdesRequest    ImageonSensorRequest    HdmiInternalRequest ImageonCaptureRequest ImageonSerdesIndication ImageonSensorIndication HdmiInternalIndication
BSVFILES = $(CONNECTALDIR)/lib/bsv/IserdesDatadeser.bsv $(CONNECTALDIR)/lib/bsv/HDMI.bsv $(CONNECTALDIR)/lib/bsv/Imageon.bsv Top.bsv
CPPFILES=testimagecapture.cpp
CONNECTALFLAGS = -C $(BOARD)/sources/imageon-$(BOARD).xdc --tcl clock.tcl
CONNECTALFLAGS += -D USE_I2C1 -D PinType=ImageCapturePins
NUMBER_OF_MASTERS = 1
#CONNECTALFLAGS += -D TRACE_AXI

ifeq ($(BOARD),zedboard)
  CONNECTALFLAGS += -D USE_I2C0
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

include ../../Makefile.connectal

