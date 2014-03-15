
BSVDIR=../../bsv
LIBBSVDIR=../../lib/bsv
GRALLOCDIR=../../gralloc
S2H = HdmiControlRequest HdmiInternalRequest DmaConfig
H2S = HdmiInternalIndication DmaIndication
BSVFILES = $(LIBBSVDIR)/HdmiDisplay.bsv $(LIBBSVDIR)/HDMI.bsv Top.bsv
CPPFILES= $(addprefix ../../gralloc/, testhdmidisplay.cpp)
XBSVFLAGS = -C hdmidisplay-$(BOARD).xdc
Dma = Dma
PINS = Std
TOP=ZynqTop.bsv
MKTOP=mkHdmiZynqTop

include ../../Makefile.common
