
CONNECTALDIR?=../..
S2H_INTERFACES = MemreadRequest:Memread.request
H2S_INTERFACES = Memread\#\(\`NumberOfMasters\):MemreadIndication
MEM_INTERFACES = lMemread.dmaClients,nil
BSVFILES = Memread.bsv
CPPFILES=../memread/testmemread.cpp

NUMBER_OF_MASTERS =4
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memread
#CONNECTALFLAGS=--bscflags " -D TRACE_AXI"
include $(CONNECTALDIR)/Makefile.connectal

