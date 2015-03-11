
CONNECTALDIR?=../..
S2H_INTERFACES = MemwriteRequest:Memwrite.request
H2S_INTERFACES = Memwrite:MemwriteIndication
MEM_INTERFACES = nil,lMemwrite.dmaClient
BSVFILES = Memwrite.bsv
CPPFILES=testmemwrite.cpp

CONNECTALFLAGS += --bscflags " -show-schedule"

include $(CONNECTALDIR)/Makefile.connectal

