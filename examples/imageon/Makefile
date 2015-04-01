
CONNECTALDIR?=../..
S2H_INTERFACES = ImageonSerdesRequest:ImageonCapture.serdes_request ImageonSensorRequest:ImageonCapture.sensor_request HdmiGeneratorRequest:ImageonCapture.hdmi_request ImageonCaptureRequest:ImageonCapture.capture_request
H2S_INTERFACES = ImageonCapture:ImageonSerdesIndication,ImageonSensorIndication,HdmiGeneratorIndication
MEM_INTERFACES = nil,lImageonCapture.dmaClient
BSVFILES = $(CONNECTALDIR)/lib/bsv/IserdesDatadeserIF.bsv \
    $(CONNECTALDIR)/lib/bsv/HDMI.bsv \
    $(CONNECTALDIR)/lib/bsv/Imageon.bsv \
    ImageonCapture.bsv

CPPFILES=testimagecapture.cpp
CONNECTALFLAGS = -D USE_I2C1
PINOUT_FILE += imageon-fmc.json
PIN_TYPE = ImageonCapturePins
PIN_BINDINGS ?= fmc:fmc1
NUMBER_OF_MASTERS = 1
ifeq ($(BOARD),zedboard)
    CONNECTALFLAGS += -D USE_I2C0 
    PINOUT_FILE += imageon-zedboard.json
endif
AUTOTOP = --interface pins:ImageonCapture.pins --importfiles ImageonCapture

include $(CONNECTALDIR)/Makefile.connectal
