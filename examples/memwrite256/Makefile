CONNECTALDIR?=../..
S2H_INTERFACES = MemwriteRequest:Memwrite.request
H2S_INTERFACES = Memwrite:MemwriteIndication
MEM_WRITE_INTERFACES = lMemwrite.dmaClient

BSVFILES = ../memwrite/Memwrite.bsv
CPPFILES=../memwrite/testmemwrite.cpp
CONNECTALFLAGS += --bscflags " -show-schedule"
CONNECTALFLAGS += -D DataBusWidth=256
CONNECTALFLAGS += -D USE_ACP
# CONNECTALFLAGS += -D NumEngineServers=4
CONNECTALFLAGS += --mainclockperiod=8 -D USE_WIDE_WIDTH

include $(CONNECTALDIR)/Makefile.connectal
