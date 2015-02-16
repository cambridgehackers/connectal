
CONNECTALDIR?=../..
S2H_INTERFACES = Memread2Request:Memread2.request
H2S_INTERFACES = Memread2Indication:Memread2
MEM_INTERFACES = MemServer.request:/cons\(lMemread2.dmaClient0,cons\(lMemread2.dmaClient1,nil\)\),cons\(lMMU,nil\):PhysAddrWidth,DataBusWidth,\`NumberOfMasters:mkMemServerR
BSVFILES = Memread2.bsv
# $(CONNECTALDIR)/lib/deprecated/DmaUtils.bsv
CPPFILES=testmemread2.cpp

include $(CONNECTALDIR)/Makefile.connectal
