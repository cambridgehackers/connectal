
CONNECTALDIR?=../..
S2H_INTERFACES = MemlatencyRequest:Memlatency.request
H2S_INTERFACES = Memlatency:MemlatencyIndication
MEM_INTERFACES = mkMemServerRW:lMemlatency.dmaReadClient,lMemlatency.dmaWriteClient
BSVFILES = Memlatency.bsv
CPPFILES = testmemlatency.cpp

include $(CONNECTALDIR)/Makefile.connectal
