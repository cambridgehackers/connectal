
CONNECTALDIR?=../..
S2H_INTERFACES = StrstrRequest:Strstr.request::64,64
H2S_INTERFACES = StrstrIndication:Strstr::64,64
MEM_INTERFACES = MemServer.request:/cons\(lStrstr.config_read_client,cons\(lStrstr.haystack_read_client,nil\)\),cons\(lMMU,nil\):PhysAddrWidth,DataBusWidth,\`NumberOfMasters:mkMemServerR

BSVFILES = $(CONNECTALDIR)/lib/strstr/bsv/Strstr.bsv
CPPFILES=teststrstr.cpp
CONNECTALFLAGS += -D DEGPAR=2
CONNECTALFLAGS += -I $(CONNECTALDIR)/lib/strstr/cpp

include $(CONNECTALDIR)/Makefile.connectal
