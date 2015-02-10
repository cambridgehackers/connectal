
CONNECTALDIR?=../..
INTERFACES = MemcpyRequest MemcpyIndication
BSVFILES = Memcpy.bsv
CPPFILES=testmemcpy.cpp

AUTOTOP = -w MemcpyRequest:Memcpy -y MemcpyIndication:Memcpy
AUTOTOP += -m mkMemServerRW:Memcpy:Memcpy

include $(CONNECTALDIR)/Makefile.connectal
