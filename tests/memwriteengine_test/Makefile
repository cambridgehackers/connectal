
CONNECTALDIR?=../..
S2H_INTERFACES = MemwriteRequest:Memwrite.request
H2S_INTERFACES = Memwrite:MemwriteIndication
MEM_INTERFACES = nil,lMemwrite.dmaClients
BSVFILES = Memwrite.bsv
CPPFILES = testmemwrite.cpp

ifeq ("$(BOARD)","xsim")
AUTOTOP = --bluenoc
endif

include $(CONNECTALDIR)/Makefile.connectal

