
CONNECTALDIR?=../..
S2H_INTERFACES = MemcopyRequest:Memcopy.request
H2S_INTERFACES = Memcopy:MemcopyIndication
MEM_INTERFACES = lMemcopy.readClients,lMemcopy.writeClients
BSVFILES = ../memserver_copy/Memcopy.bsv
CPPFILES = ../memserver_copy/testmemcopy.cpp

CONNECTALFLAGS += -D USE_ACP -P mkConnectalTop -D DataBusSize=128

include $(CONNECTALDIR)/Makefile.connectal
