
CONNECTALDIR?=../..
S2H_INTERFACES = MemwriteRequest:Memwrite.request
H2S_INTERFACES = MemwriteIndication:Memwrite
MEM_INTERFACES = MemServer.request:/lMemwrite.dmaClient,cons\(lMMU,nil\):PhysAddrWidth,DataBusWidth,\`NumberOfMasters:mkMemServerW
BSVFILES = Memwrite.bsv
CPPFILES=testmemwrite.cpp

CONNECTALFLAGS += --bscflags " -show-schedule"

include $(CONNECTALDIR)/Makefile.connectal

