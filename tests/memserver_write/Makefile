CONNECTALDIR?=../..
S2H_INTERFACES = MemwriteRequest:Memwrite.request
H2S_INTERFACES = Memwrite:MemwriteIndication
MEM_WRITE_INTERFACES = lMemwrite.dmaClients

BSVFILES = Memwrite.bsv
CPPFILES = testmemwrite.cpp
CONNECTALFLAGS += -D USE_ACP -P mkConnectalTop -D BYTE_ENABLES

include $(CONNECTALDIR)/Makefile.connectal
