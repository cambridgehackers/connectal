
CONNECTALDIR?=../..
INTERFACES = StrstrRequest StrstrIndication
BSVFILES = $(CONNECTALDIR)/lib/strstr/bsv/Strstr.bsv Top.bsv
CPPFILES=teststrstr.cpp
CONNECTALFLAGS += -D DEGPAR=2
CONNECTALFLAGS += -I $(CONNECTALDIR)/lib/strstr/cpp


include $(CONNECTALDIR)/Makefile.connectal
