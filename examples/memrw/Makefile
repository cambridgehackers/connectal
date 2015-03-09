
CONNECTALDIR?=../..
S2H_INTERFACES = MemrwRequest:Memrw.request
H2S_INTERFACES = MemrwIndication:Memrw
MEM_INTERFACES = MemServer.request:/lMemrw.dmaReadClient,lMemrw.dmaWriteClient,cons\(lMMU,nil\):PhysAddrWidth,DataBusWidth,\`NumberOfMasters:mkMemServerRW
BSVFILES = Memrw.bsv
CPPFILES=testmemrw.cpp

include $(CONNECTALDIR)/Makefile.connectal
