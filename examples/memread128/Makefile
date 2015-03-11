
CONNECTALDIR?=../..
S2H_INTERFACES = MemreadRequest:Memread.request
H2S_INTERFACES = Memread:MemreadIndication
MEM_INTERFACES = lMemread.dmaClient,nil
BSVFILES = Memread.bsv
CPPFILES=testmemread.cpp
CONNECTALFLAGS += --bscflags " -D DataBusWidth=128"

include $(CONNECTALDIR)/Makefile.connectal

