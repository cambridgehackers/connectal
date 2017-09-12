CONNECTALDIR?=../..
S2H_INTERFACES = MemwriteRequest:Memwrite.request
H2S_INTERFACES = Memwrite:MemwriteIndication
MEM_WRITE_INTERFACES = lMemwrite.dmaClient

BSVFILES = ../memwrite/Memwrite.bsv
CPPFILES=../memwrite/testmemwrite.cpp
CONNECTALFLAGS += --bscflags " -show-schedule"
CONNECTALFLAGS += -D DataBusWidth=128
CONNECTALFLAGS += -D USE_ACP

include $(CONNECTALDIR)/Makefile.connectal
