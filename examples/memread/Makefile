
CONNECTALDIR?=../..
INTERFACES = MemreadRequest MemreadIndication
BSVFILES = Memread.bsv
CPPFILES=testmemread.cpp

AUTOTOP = -w MemreadRequest:Memread.request -p MemreadIndication:Memread
AUTOTOP += -m mkMemServerR:Memread.dmaClient

include $(CONNECTALDIR)/Makefile.connectal

