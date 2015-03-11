
CONNECTALDIR?=../..
S2H_INTERFACES = MemwriteRequest:Memwrite.request
H2S_INTERFACES = Memwrite:MemwriteIndication::\`NumberOfMasters
MEM_INTERFACES = mkMemServerW:lMemwrite.dmaClients
BSVFILES = Memwrite.bsv
CPPFILES=testmemwrite.cpp

NUMBER_OF_MASTERS =4
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memwrite

include $(CONNECTALDIR)/Makefile.connectal

