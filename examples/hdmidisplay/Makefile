
CONNECTALDIR?=../..
LIBBSVDIR=$(CONNECTALDIR)/lib/bsv
ifeq ($(BOARD),bluesim)
H2S_INTERFACES = HdmiDisplay:HdmiDisplayIndication,HdmiGeneratorIndication:defaultClock
else
H2S_INTERFACES = HdmiDisplay:HdmiDisplayIndication,HdmiGeneratorIndication:host.ps7.fclkclk\[1\]
endif
S2H_INTERFACES = HdmiDisplayRequest:HdmiDisplay.displayRequest HdmiGeneratorRequest:HdmiDisplay.internalRequest
MEM_INTERFACES = lHdmiDisplay.dmaClient,nil
AUTOTOP = --importfiles HDMI --importfiles HDMI16 --importfiles PS7LIB --interface pins:HdmiDisplay.hdmi

BSVFILES = $(LIBBSVDIR)/HdmiDisplay.bsv $(LIBBSVDIR)/HDMI.bsv $(CONNECTALDIR)/lib/deprecated/DmaUtils.bsv HDMI16.bsv
CPPFILES= testhdmidisplay.cpp
CONNECTALFLAGS = -C hdmidisplay-$(BOARD).xdc -D IMPORT_HOSTIF
PIN_TYPE = HDMI16
ifeq ($(BOARD),zedboard)
CONNECTALFLAGS += -D USE_I2C0
endif
REALCONNECTALDIR=$(realpath ../..)
CONNECTALFLAGS += -q --bscflags " -Xc++" --bscflags " -DLIBNAME=\\\"$(REALCONNECTALDIR)/examples/hdmidisplay/bluesim/jni/libHdmi.so\\\""
CONNECTALFLAGS += -D BSIMRESPONDER=mkResponder -m $(CONNECTALDIR)/examples/hdmidisplay/BsimHdmi.cpp 

include $(CONNECTALDIR)/Makefile.connectal
