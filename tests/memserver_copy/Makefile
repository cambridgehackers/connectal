CONNECTALDIR?=../..
S2H_INTERFACES = MemcopyRequest:Memcopy.request
H2S_INTERFACES = Memcopy:MemcopyIndication
MEM_READ_INTERFACES = lMemcopy.readClients
MEM_WRITE_INTERFACES = lMemcopy.writeClients

BSVFILES = ../memserver_copy/Memcopy.bsv
CPPFILES = ../memserver_copy/testmemcopy.cpp
CONNECTALFLAGS += -D USE_ACP -P mkConnectalTop

include $(CONNECTALDIR)/Makefile.connectal
