
CONNECTALDIR?=../..
INTERFACES = MemwriteRequest MemwriteIndication
BSVFILES = Memwrite.bsv
CPPFILES=testmemwrite.cpp

AUTOTOP = -w MemwriteRequest:Memwrite -y MemwriteIndication:Memwrite
AUTOTOP += -m mkMemServerW:Memwrite
CONNECTALFLAGS += --bscflags " -show-schedule"

include $(CONNECTALDIR)/Makefile.connectal

