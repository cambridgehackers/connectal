
CONNECTALDIR?=../..
S2H_INTERFACES = MemwriteRequest:Memwrite.request
H2S_INTERFACES = Memwrite:MemwriteIndication
MEM_INTERFACES = nil,lMemwrite.dmaClients
BSVFILES = Memwrite.bsv
CPPFILES = testmemwrite.cpp

CONNECTALFLAGS += -D USE_ACP -P mkConnectalTop

include $(CONNECTALDIR)/Makefile.connectal

