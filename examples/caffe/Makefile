CONNECTALDIR?=../..

S2H_INTERFACES = ConvRequest:Conv.request
H2S_INTERFACES = Conv:ConvIndication
# Direct convolution/gradient calculation version
CPPFILES = $(CONNECTALDIR)/lib/cpp/connectal_conv.cpp
BSVFILES = Conv.bsv
# Matrix multiply version
#CPPFILES = $(CONNECTALDIR)/lib/cpp/connectal_convmm.cpp
CONNECTALFLAGS += --shared
#CONNECTALFLAGS += --nohardware
NUMBER_OF_MASTERS =0

include $(CONNECTALDIR)/Makefile.connectal
