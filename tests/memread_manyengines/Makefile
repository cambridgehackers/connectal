
CONNECTALDIR?=../..
S2H_INTERFACES = MemreadRequest:Memread.request
H2S_INTERFACES = Memread\#\(\`NumEngines\):MemreadIndication
MEM_INTERFACES = lMemread.dmaClients,nil
BSVFILES = Memread.bsv
CPPFILES=testmemread.cpp
CONNECTALFLAGS += --bscflags " -D DataBusWidth=128 -D NumEngines=4"
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memread

include $(CONNECTALDIR)/Makefile.connectal

