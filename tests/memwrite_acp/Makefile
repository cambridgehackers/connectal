CONNECTALDIR?=../..
S2H_INTERFACES = MemwriteRequest:Memwrite.request
H2S_INTERFACES = Memwrite:MemwriteIndication
MEM_WRITE_INTERFACES = lMemwrite.dmaClient

BSVFILES = Memwrite.bsv
CPPFILES = testmemwrite.cpp
CONNECTALFLAGS += -D USE_ACP

include $(CONNECTALDIR)/Makefile.connectal
