CONNECTALDIR?=../..
S2H_INTERFACES = ImageonSerdesRequest:ImageonCapture.serdes_request HdmiGeneratorRequest:ImageonCapture.hdmi_request ImageonCaptureRequest:ImageonCapture.capture_request
H2S_INTERFACES = ImageonCapture:ImageonSerdesIndication,HdmiGeneratorIndication,ImageonCaptureIndication
MEM_WRITE_INTERFACES = lImageonCapture.dmaClient

BSVFILES = $(CONNECTALDIR)/lib/bsv/IserdesDatadeserIF.bsv $(CONNECTALDIR)/lib/bsv/HDMI.bsv ImageonCapture.bsv
CPPFILES=testimagecapture.cpp
CONNECTALFLAGS = -D USE_I2C1
PINOUT_FILE += imageon-fmc.json
PIN_TYPE = ImageonCapturePins
PIN_TYPE_INCLUDE = ImageonCapturePins
ifeq ($(BOARD),zedboard)
    CONNECTALFLAGS += -D USE_I2C0 
    PINOUT_FILE += imageon-zedboard.json
    PIN_BINDINGS ?= fmc:fmc1
else
    PIN_BINDINGS ?= fmc:fmc2
endif
CONNECTALFLAGS += -C imageon-clocks.xdc --tcl clock.tcl
AUTOTOP = --interface pins:ImageonCapture.pins

include $(CONNECTALDIR)/Makefile.connectal
