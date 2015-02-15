
CONNECTALDIR?=../..
S2H_INTERFACES = MemcpyRequest:Memcpy.request
H2S_INTERFACES = MemcpyIndication:Memcpy
BSVFILES = Memcpy.bsv
CPPFILES=testmemcpy.cpp

AUTOTOP += -m mkMemServerRW:Memcpy.dmaReadClient:Memcpy.dmaWriteClient

include $(CONNECTALDIR)/Makefile.connectal
