CONNECTALDIR?=../..

# Direct convolution/gradient calculation version
#CPPFILES = $(CONNECTALDIR)/lib/cpp/connectal_conv.cpp
# Matrix multiply version
CPPFILES = $(CONNECTALDIR)/lib/cpp/connectal_convmm.cpp
CONNECTALFLAGS += --shared
CONNECTALFLAGS += --nohardware
NUMBER_OF_MASTERS =0

include $(CONNECTALDIR)/Makefile.connectal

