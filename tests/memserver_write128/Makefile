
CONNECTALDIR?=../..
MSWDIR=../memserver_write/
S2H_INTERFACES = MemwriteRequest:Memwrite.request
H2S_INTERFACES = Memwrite:MemwriteIndication
MEM_INTERFACES = nil,lMemwrite.dmaClients
BSVFILES = $(MSWDIR)/Memwrite.bsv
CPPFILES = $(MSWDIR)/testmemwrite.cpp

CONNECTALFLAGS += -D USE_ACP -P mkConnectalTop -D DataBusWidth=128

include $(CONNECTALDIR)/Makefile.connectal

