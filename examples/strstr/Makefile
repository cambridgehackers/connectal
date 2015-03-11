
CONNECTALDIR?=../..
S2H_INTERFACES = StrstrRequest:Strstr.request::64,64
H2S_INTERFACES = Strstr:StrstrIndication::64,64
MEM_INTERFACES = mkMemServerR:cons\(lStrstr.config_read_client,cons\(lStrstr.haystack_read_client,nil\)\)

BSVFILES = $(CONNECTALDIR)/lib/strstr/bsv/Strstr.bsv
CPPFILES=teststrstr.cpp
CONNECTALFLAGS += -D DEGPAR=2
CONNECTALFLAGS += -I $(CONNECTALDIR)/lib/strstr/cpp

include $(CONNECTALDIR)/Makefile.connectal
