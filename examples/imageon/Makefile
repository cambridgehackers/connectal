
CONNECTALDIR?=../..
INTERFACES = ImageonSerdesRequest    ImageonSensorRequest    HdmiInternalRequest ImageonCaptureRequest ImageonSerdesIndication ImageonSensorIndication HdmiInternalIndication
BSVFILES = $(CONNECTALDIR)/lib/bsv/IserdesDatadeser.bsv $(CONNECTALDIR)/lib/bsv/HDMI.bsv $(CONNECTALDIR)/lib/bsv/Imageon.bsv Top.bsv
CPPFILES=testimagecapture.cpp
CONNECTALFLAGS = -C $(BOARD)/sources/imageon-$(BOARD).xdc # --tcl clock.tcl
CONNECTALFLAGS += -D USE_I2C1
PIN_TYPE = ImageCapturePins
NUMBER_OF_MASTERS = 1
#CONNECTALFLAGS += -D TRACE_AXI

ifeq ($(BOARD),zedboard)
  CONNECTALFLAGS += -D USE_I2C0
endif

PIN_BINDINGS ?= -b fmc:fmc1

gentarget:: $(BOARD)/sources/imageon-$(BOARD).xdc

$(BOARD)/sources/imageon-$(BOARD).xdc: imageon-fmc.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
	$(CONNECTALDIR)/scripts/generate-constraints.py $(PIN_BINDINGS) -o $(BOARD)/sources/imageon-$(BOARD).xdc $(CONNECTALDIR)/boardinfo/$(BOARD).json imageon-fmc.json

include $(CONNECTALDIR)/Makefile.connectal

