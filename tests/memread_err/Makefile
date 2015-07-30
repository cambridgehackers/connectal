CONNECTALDIR ?= ../..
S2H_INTERFACES = MemreadRequest:Memread.request
H2S_INTERFACES = Memread:MemreadIndication
MEM_INTERFACES = cons\(lMemread.dmaClient,nil\),nil

BSVFILES = Memread.bsv
CPPFILES=testmemread.cpp

include $(CONNECTALDIR)/Makefile.connectal
