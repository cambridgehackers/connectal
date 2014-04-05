
S2H = ImageCaptureRequest ImageonSerdesRequest HdmiInternalRequest ImageonSensorRequest
H2S = ImageCaptureIndication ImageonSerdesIndication HdmiInternalIndication
BSVFILES = ImageCapture.bsv $(XBSVDIR)/lib/bsv/IserdesDatadeser.bsv $(XBSVDIR)/lib/bsv/HDMI.bsv $(XBSVDIR)/lib/bsv/Imageon.bsv Top.bsv
CPPFILES=testimagecapture.cpp
XBSVFLAGS = -C imageon-$(BOARD).xdc --tcl clock.tcl
Dma = 
PINS = ImageonVita
#XBSVFLAGS += --bscflags " -D TRACE_AXI"

ifeq ($(BOARD),zedboard)
HAS_PS7=true
endif
ifeq ($(BOARD),zc702)
HAS_PS7=true
endif

ifeq ($(HAS_PS7),true)
TOP=ImageonZynqTop.bsv
MKTOP=mkImageonZynqTop
else
TOP=ImageonPcieTop.bsv
MKTOP=mkImageonPcieTop
endif

gen:: pregen

pregen: imageon-$(BOARD).xdc

imageon-$(BOARD).xdc: imageon-fmc.json ../../boardinfo/$(BOARD).json
	../../scripts/generate-constraints.py ../../boardinfo/$(BOARD).json imageon-fmc.json > imageon-$(BOARD).xdc

include ../../Makefile.common

