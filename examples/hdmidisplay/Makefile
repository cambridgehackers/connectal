
BSVDIR=../../bsv
LIBBSVDIR=../../lib/bsv
GRALLOCDIR=../../gralloc
S2H = HdmiDisplayRequest HdmiInternalRequest DmaConfig
H2S = HdmiDisplayIndication HdmiInternalIndication DmaIndication
BSVFILES = $(LIBBSVDIR)/HdmiDisplay.bsv $(LIBBSVDIR)/HDMI.bsv Top.bsv ../../lib/deprecated/DmaUtils.bsv
CPPFILES= testhdmidisplay.cpp
XBSVFLAGS = -C hdmidisplay-$(BOARD).xdc -D USES_FCLK1 -D PinType=HDMI16
ifeq ($(BOARD),zedboard)
XBSVFLAGS += -D USES_I2C0
endif

#XBSVFLAGS=--bscflags " -D TRACE_AXI"

include ../../Makefile.common
