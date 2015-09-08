CONNECTALDIR?=../..
S2H_INTERFACES = StrstrRequest:Strstr.request
H2S_INTERFACES = Strstr\#\(64,64\):StrstrIndication
MEM_READ_INTERFACES = "append(lStrstr.config_read_client,lStrstr.haystack_read_client)"

BSVFILES = $(CONNECTALDIR)/lib/strstr/bsv/Strstr.bsv
CPPFILES=teststrstr.cpp
CONNECTALFLAGS += -D DEGPAR=2
CONNECTALFLAGS += -I $(CONNECTALDIR)/lib/strstr/cpp

include $(CONNECTALDIR)/Makefile.connectal
