
CONNECTALDIR?=../..
INTERFACES = MemreadRequest MemreadIndication
BSVFILES = Memread.bsv
CPPFILES=testmemread.cpp

AUTOTOP = -w MemreadRequest:Memread -y MemreadIndication:Memread
AUTOTOP += -m mkMemServerR

include $(CONNECTALDIR)/Makefile.connectal

