
CONNECTALDIR?=../..
S2H_INTERFACES = MemlatencyRequest:Memlatency.request
H2S_INTERFACES = MemlatencyIndication:Memlatency
MEM_INTERFACES = MemServer.request:/lMemlatency.dmaReadClient,lMemlatency.dmaWriteClient,cons\(lMMU,nil\):PhysAddrWidth,DataBusWidth,\`NumberOfMasters:mkMemServerRW
BSVFILES = Memlatency.bsv
CPPFILES = testmemlatency.cpp

include $(CONNECTALDIR)/Makefile.connectal
