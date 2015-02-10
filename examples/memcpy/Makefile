
CONNECTALDIR?=../..
INTERFACES = MemcpyRequest MemcpyIndication
BSVFILES = Memcpy.bsv
CPPFILES=testmemcpy.cpp

AUTOTOP = -w MemcpyRequest:Memcpy -p MemcpyIndication:Memcpy
AUTOTOP += -m mkMemServerRW:Memcpy.dmaReadClient:Memcpy.dmaWriteClient

include $(CONNECTALDIR)/Makefile.connectal
