
CONNECTALDIR?=../..
S2H_INTERFACES = MemcopyRequest:Memcopy.request
H2S_INTERFACES = Memcopy:MemcopyIndication
MEM_INTERFACES = lMemcopy.readClients,lMemcopy.writeClients
BSVFILES = Memcopy.bsv
CPPFILES = testmemcopy.cpp

CONNECTALFLAGS += -D USE_ACP -P mkConnectalTop

include $(CONNECTALDIR)/Makefile.connectal

