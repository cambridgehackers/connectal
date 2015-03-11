
CONNECTALDIR?=../..
LIBBSVDIR=$(CONNECTALDIR)/lib/bsv
ifeq ($(BOARD),bluesim)
H2S_INTERFACES = HdmiDisplay:HdmiDisplayIndication:defaultClock HdmiDisplay:HdmiInternalIndication
else
H2S_INTERFACES = HdmiDisplay:HdmiDisplayIndication:host.ps7.fclkclk\[1\] HdmiDisplay:HdmiInternalIndication:host.ps7.fclkclk\[1\]
endif
S2H_INTERFACES = HdmiDisplayRequest:HdmiDisplay.displayRequest HdmiInternalRequest:HdmiDisplay.internalRequest
MEM_INTERFACES = mkMemServerR:cons\(lHdmiDisplay.dmaClient,nil\)
AUTOTOP = --importfiles HDMI --importfiles HDMI16 --interface pins:HdmiDisplay.hdmi

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
