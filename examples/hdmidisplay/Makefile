
BSVDIR=../../bsv
LIBBSVDIR=../../lib/bsv
GRALLOCDIR=../../gralloc
S2H = HdmiControlRequest HdmiInternalRequest DmaConfig
H2S = HdmiInternalIndication DmaIndication
BSVFILES = $(LIBBSVDIR)/HdmiDisplay.bsv $(LIBBSVDIR)/HDMI.bsv Top.bsv
CPPFILES= $(addprefix ../../gralloc/, testhdmidisplay.cpp)
Dma = Dma
PINS = Std
TOP=ZynqTop.bsv
MKTOP=mkZynqTopClk1

include ../../Makefile.common
