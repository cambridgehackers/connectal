
CONNECTALDIR?=../..
INTERFACES = MemwriteRequest MemwriteIndication
BSVFILES = Memwrite.bsv
CPPFILES=testmemwrite.cpp

AUTOTOP = -w MemwriteRequest:Memwrite -p MemwriteIndication:Memwrite
AUTOTOP += -m mkMemServerW:Memwrite.dmaClient
CONNECTALFLAGS += --bscflags " -show-schedule"

include $(CONNECTALDIR)/Makefile.connectal

