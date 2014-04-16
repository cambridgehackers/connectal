
BSVDIR=../../bsv
LIBBSVDIR=../../lib/bsv
GRALLOCDIR=../../gralloc
S2H = HdmiDisplayRequest HdmiInternalRequest DmaConfig
H2S = HdmiDisplayIndication HdmiInternalIndication DmaIndication
BSVFILES = $(LIBBSVDIR)/HdmiDisplay.bsv $(LIBBSVDIR)/HDMI.bsv Top.bsv
CPPFILES= testhdmidisplay.cpp
XBSVFLAGS = -C hdmidisplay-$(BOARD).xdc
Dma = Dma
PINS = Std
TOP=ZynqTop.bsv
MKTOP=mkHdmiZynqTop
#XBSVFLAGS=--bscflags " -D TRACE_AXI"

include ../../Makefile.common
