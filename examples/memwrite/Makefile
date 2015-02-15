
CONNECTALDIR?=../..
S2H_INTERFACES = MemwriteRequest:Memwrite.request
H2S_INTERFACES = MemwriteIndication:Memwrite
BSVFILES = Memwrite.bsv
CPPFILES=testmemwrite.cpp

AUTOTOP += -m mkMemServerW:Memwrite.dmaClient
CONNECTALFLAGS += --bscflags " -show-schedule"

include $(CONNECTALDIR)/Makefile.connectal

