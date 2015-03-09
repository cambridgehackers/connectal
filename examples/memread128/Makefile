
CONNECTALDIR?=../..
S2H_INTERFACES = MemreadRequest:Memread.request
H2S_INTERFACES = MemreadIndication:Memread
MEM_INTERFACES = MemServer.request:/lMemread.dmaClient,cons\(lMMU,nil\):PhysAddrWidth,DataBusWidth,\`NumberOfMasters:mkMemServerR
BSVFILES = Memread.bsv
CPPFILES=testmemread.cpp
CONNECTALFLAGS += --bscflags " -D DataBusWidth=128"

include $(CONNECTALDIR)/Makefile.connectal

