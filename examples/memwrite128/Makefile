
CONNECTALDIR?=../..
S2H_INTERFACES = MemwriteRequest:Memwrite.request
H2S_INTERFACES = Memwrite:MemwriteIndication
MEM_INTERFACES = nil,lMemwrite.dmaClient
BSVFILES = ../memwrite/Memwrite.bsv
CPPFILES=../memwrite/testmemwrite.cpp

CONNECTALFLAGS += --bscflags " -show-schedule"
CONNECTALFLAGS += -D DataBusWidth=128

include $(CONNECTALDIR)/Makefile.connectal

