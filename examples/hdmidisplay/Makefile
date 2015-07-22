
CONNECTALDIR?=../..
LIBBSVDIR=$(CONNECTALDIR)/lib/bsv
ifeq ($(BOARD),bluesim)
H2S_INTERFACES = HdmiDisplay:HdmiDisplayIndication,HdmiGeneratorIndication:defaultClock
else
H2S_INTERFACES = HdmiDisplay:HdmiDisplayIndication,HdmiGeneratorIndication:host.ps7.fclkclk\[1\]
endif
S2H_INTERFACES = HdmiDisplayRequest:HdmiDisplay.displayRequest HdmiGeneratorRequest:HdmiDisplay.internalRequest
MEM_INTERFACES = lHdmiDisplay.dmaClient,nil
AUTOTOP = --importfiles HDMI --importfiles PS7LIB --interface pins:HdmiDisplay.hdmi

BSVFILES = $(LIBBSVDIR)/HdmiDisplay.bsv $(LIBBSVDIR)/HDMI.bsv $(CONNECTALDIR)/lib/deprecated/DmaUtils.bsv HDMI16.bsv
CPPFILES= testhdmidisplay.cpp
CONNECTALFLAGS = -C hdmidisplay-$(BOARD).xdc -D IMPORT_HOSTIF
PIN_TYPE = HDMI16
PIN_TYPE_INCLUDE = HDMI16
ifeq ($(BOARD),zedboard)
CONNECTALFLAGS += -D USE_I2C0
I2C_JSON_FILE = --pinoutfile i2c.json
endif
REALCONNECTALDIR=$(realpath ../..)
CONNECTALFLAGS += -q -D LIBNAME=\\\"$(REALCONNECTALDIR)/examples/hdmidisplay/bluesim/jni/libHdmi.so\\\"
CONNECTALFLAGS += -D BSIMRESPONDER=mkResponder -m $(CONNECTALDIR)/examples/hdmidisplay/BsimHdmi.cpp 

CONNECTALFLAGS += -C $(BOARD)/sources/hdmi.xdc

gentarget:: $(BOARD)/sources/hdmi.xdc

$(BOARD)/sources/hdmi.xdc: hdmi.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
ifneq ($(BOARD),bluesim)
	$(CONNECTALDIR)/scripts/generate-constraints.py $(PIN_BINDINGS) -o $(BOARD)/sources/hdmi.xdc --boardfile $(CONNECTALDIR)/boardinfo/$(BOARD).json --pinoutfile hdmi.json $(I2C_JSON_FILE)
endif

include $(CONNECTALDIR)/Makefile.connectal
