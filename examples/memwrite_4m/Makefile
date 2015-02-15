
CONNECTALDIR?=../..
S2H_INTERFACES = MemwriteRequest:Memwrite.request::\`NumberOfMasters
H2S_INTERFACES = MemwriteIndication:Memwrite::\`NumberOfMasters
BSVFILES = Memwrite.bsv
CPPFILES=testmemwrite.cpp

AUTOTOP += -m mkMemServerW:Memwrite.dmaClients

NUMBER_OF_MASTERS =4
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memwrite

include $(CONNECTALDIR)/Makefile.connectal

