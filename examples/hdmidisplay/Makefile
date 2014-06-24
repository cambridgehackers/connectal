
BSVDIR=../../bsv
LIBBSVDIR=../../lib/bsv
GRALLOCDIR=../../gralloc
S2H = HdmiDisplayRequest HdmiInternalRequest DmaConfig
H2S = HdmiDisplayIndication HdmiInternalIndication DmaIndication
BSVFILES = $(LIBBSVDIR)/HdmiDisplay.bsv $(LIBBSVDIR)/HDMI.bsv Top.bsv ../../lib/deprecated/DmaUtils.bsv
CPPFILES= testhdmidisplay.cpp
XBSVFLAGS = -C hdmidisplay-$(BOARD).xdc -D USES_FCLK1 -D PinType=HDMI16
ifeq ($(BOARD),zedboard)
XBSVFLAGS += -D USE_I2C0
endif
REALXBSVDIR=$(realpath $(XBSVDIR))
XBSVFLAGS += --bscflags " -Xc++" --bscflags " -DEXECDIRECTORY=\\\"$(REALXBSVDIR)/examples/hdmidisplay/subproj\\\""
XBSVFLAGS += -D BSIMRESPONDER=mkResponder -m $(XBSVDIR)/examples/hdmidisplay/BsimHdmi.cpp 

#XBSVFLAGS=--bscflags " -D TRACE_AXI"

include ../../Makefile.common
