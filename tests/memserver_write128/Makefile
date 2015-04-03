
CONNECTALDIR?=../..
MSWDIR=../memserver_write/
INTERFACES = MemwriteRequest MemwriteIndication
BSVFILES = $(MSWDIR)/Memwrite.bsv $(MSWDIR)/Top.bsv
CPPFILES = $(MSWDIR)/testmemwrite.cpp

CONNECTALFLAGS += -D USE_ACP -P mkConnectalTop -D DATA_BUS_WIDTH=128

include $(CONNECTALDIR)/Makefile.connectal

