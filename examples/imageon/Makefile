
CONNECTALDIR?=../..
INTERFACES = ImageonSerdesRequest ImageonSensorRequest HdmiGeneratorRequest ImageonCaptureRequest ImageonSerdesIndication ImageonSensorIndication HdmiGeneratorIndication
BSVFILES = $(CONNECTALDIR)/lib/bsv/IserdesDatadeserIF.bsv \
    $(CONNECTALDIR)/lib/bsv/HDMI.bsv \
    $(CONNECTALDIR)/lib/bsv/Imageon.bsv \
    ImageonCapture.bsv \
    Top.bsv
CPPFILES=testimagecapture.cpp
CONNECTALFLAGS = -D USE_I2C1
PINOUT_FILE += imageon-fmc.json
PIN_TYPE = ImageCapturePins
PIN_BINDINGS ?= fmc:fmc1
NUMBER_OF_MASTERS = 1
ifeq ($(BOARD),zedboard)
    CONNECTALFLAGS += -D USE_I2C0 
    PINOUT_FILE += imageon-zedboard.json
endif

include $(CONNECTALDIR)/Makefile.connectal
