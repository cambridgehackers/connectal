CONNECTALDIR?=../..
S2H_INTERFACES = StrstrRequest:StrstrExample.request
H2S_INTERFACES = StrstrExample:StrstrIndication
MEM_READ_INTERFACES = lStrstrExample.readClients

BSVFILES = $(CONNECTALDIR)/lib/strstr/bsv/Strstr.bsv StrstrExample.bsv
CPPFILES=teststrstr.cpp
CONNECTALFLAGS += -I $(CONNECTALDIR)/lib/strstr/cpp

include $(CONNECTALDIR)/Makefile.connectal
