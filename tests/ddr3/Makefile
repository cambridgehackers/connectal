CONNECTALDIR?=../..
S2H_INTERFACES = Ddr3TestRequest:Ddr3Test.request
H2S_INTERFACES = Ddr3Test:Ddr3TestIndication
MEM_READ_INTERFACES = lDdr3Test.readClient

CONNECTALFLAGS += -D DataBusWidth=128

BSVFILES = Ddr3Test.bsv
CPPFILES=testddr3.cpp

include $(CONNECTALDIR)/Makefile.connectal
