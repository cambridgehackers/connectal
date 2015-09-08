CONNECTALDIR?=../..
S2H_INTERFACES = ConvRequest:Conv.request
H2S_INTERFACES = Conv:ConvIndication
MEM_READ_INTERFACES = lConv.readDma
MEM_WRITE_INTERFACES = lConv.writeDma

# Direct convolution/gradient calculation version
CPPFILES = $(CONNECTALDIR)/lib/cpp/connectal_conv.cpp
BSVFILES = Conv.bsv
CONNECTALFLAGS += --shared --bsvpath $(CONNECTALDIR)/lib/matmul/bsv

include $(CONNECTALDIR)/Makefile.connectal
