
CONNECTALDIR?=../..
INTERFACES = ImageonSerdesRequest ImageonSensorRequest HdmiGeneratorRequest ImageonCaptureRequest ImageonSerdesIndication ImageonSensorIndication HdmiGeneratorIndication
BSVFILES = $(CONNECTALDIR)/lib/bsv/IserdesDatadeser.bsv \
    $(CONNECTALDIR)/lib/bsv/HDMI.bsv \
    $(CONNECTALDIR)/lib/bsv/Imageon.bsv \
    ImageonCapture.bsv \
    Top.bsv
CPPFILES=testimagecapture.cpp
CONNECTALFLAGS = -C $(BOARD)/sources/imageon-$(BOARD).xdc -D USE_I2C1
PIN_TYPE = ImageCapturePins
NUMBER_OF_MASTERS = 1

ifeq ($(BOARD),zedboard)
    CONNECTALFLAGS += -D USE_I2C0
endif

PIN_BINDINGS ?= -b fmc:fmc1

gentarget:: $(BOARD)/sources/imageon-$(BOARD).xdc

$(BOARD)/sources/imageon-$(BOARD).xdc: imageon-fmc.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
	$(CONNECTALDIR)/scripts/generate-constraints.py $(PIN_BINDINGS) -o $(BOARD)/sources/imageon-$(BOARD).xdc $(CONNECTALDIR)/boardinfo/$(BOARD).json imageon-fmc.json

include $(CONNECTALDIR)/Makefile.connectal

