
CONNECTALDIR?=../..
INTERFACES = MemwriteRequest MemwriteIndication
BSVFILES = Memwrite.bsv
CPPFILES=testmemwrite.cpp

AUTOTOP = -w MemwriteRequest:Memwrite::\`NumberOfMasters -p MemwriteIndication:Memwrite::\`NumberOfMasters
AUTOTOP += -m mkMemServerW:Memwrite.dmaClients

NUMBER_OF_MASTERS =4
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memwrite

include $(CONNECTALDIR)/Makefile.connectal

