
LIBBSVDIR=../../lib/bsv
GRALLOCDIR=../../gralloc
S2H = HdmiDisplayRequest HdmiInternalRequest
H2S = HdmiDisplayIndication HdmiInternalIndication
BSVFILES = $(LIBBSVDIR)/HdmiDisplay.bsv $(LIBBSVDIR)/HDMI.bsv Top.bsv ../../lib/deprecated/DmaUtils.bsv
CPPFILES= testhdmidisplay.cpp
XBSVFLAGS = -C hdmidisplay-$(BOARD).xdc -D IMPORT_HOSTIF -D PinType=HDMI16
ifeq ($(BOARD),zedboard)
XBSVFLAGS += -D USE_I2C0
endif
REALXBSVDIR=$(realpath ../..)
XBSVFLAGS += -q --bscflags " -Xc++" --bscflags " -DLIBNAME=\\\"$(REALXBSVDIR)/examples/hdmidisplay/bluesim/jni/libHdmi.so\\\""
XBSVFLAGS += -D BSIMRESPONDER=mkResponder -m ../../examples/hdmidisplay/BsimHdmi.cpp 

include ../../Makefile.connectal
