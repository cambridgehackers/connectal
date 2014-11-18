
CONNECTALDIR?=../..
LIBBSVDIR=$(CONNECTALDIR)/lib/bsv
GRALLOCDIR=$(CONNECTALDIR)/gralloc
INTERFACES = HdmiDisplayRequest HdmiInternalRequest HdmiDisplayIndication HdmiInternalIndication
BSVFILES = $(LIBBSVDIR)/HdmiDisplay.bsv $(LIBBSVDIR)/HDMI.bsv Top.bsv $(CONNECTALDIR)/lib/deprecated/DmaUtils.bsv
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
