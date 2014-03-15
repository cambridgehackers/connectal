
S2H = ImageCaptureRequest ImageonSerdesRequest HdmiInternalRequest ImageonSensorRequest
H2S = ImageCaptureIndication ImageonSerdesIndication HdmiInternalIndication
BSVFILES = ImageCapture.bsv $(XBSVDIR)/lib/bsv/IserdesDatadeser.bsv $(XBSVDIR)/lib/bsv/HDMI.bsv $(XBSVDIR)/lib/bsv/Imageon.bsv Top.bsv
CPPFILES=testimagecapture.cpp
XBSVFLAGS = -C imageon-$(BOARD).xdc
Dma = 
PINS = ImageonVita
TOP=ImageonZynqTop.bsv
MKTOP=mkImageonZynqTop

include ../../Makefile.common

