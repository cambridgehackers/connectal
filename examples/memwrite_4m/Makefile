
CONNECTALDIR?=../..
S2H_INTERFACES = MemwriteRequest:Memwrite.request::\`NumberOfMasters
H2S_INTERFACES = MemwriteIndication:Memwrite::\`NumberOfMasters
MEM_INTERFACES = MemServer.request:/lMemwrite.dmaClients,cons\(lMMU,nil\):PhysAddrWidth,DataBusWidth,\`NumberOfMasters:mkMemServerW
BSVFILES = Memwrite.bsv
CPPFILES=testmemwrite.cpp

NUMBER_OF_MASTERS =4
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memwrite

include $(CONNECTALDIR)/Makefile.connectal

