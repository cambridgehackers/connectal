
CONNECTALDIR?=../..
S2H_INTERFACES = MemcpyRequest:Memcpy.request
H2S_INTERFACES = MemcpyIndication:Memcpy
MEM_INTERFACES = MemServer.request:/lMemcpy.dmaReadClient,lMemcpy.dmaWriteClient,cons\(lMMU,nil\):PhysAddrWidth,DataBusWidth,\`NumberOfMasters:mkMemServerRW
BSVFILES = Memcpy.bsv
CPPFILES=testmemcpy.cpp

include $(CONNECTALDIR)/Makefile.connectal
