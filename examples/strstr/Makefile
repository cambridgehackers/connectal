
CONNECTALDIR?=../..
INTERFACES = StrstrRequest StrstrIndication
BSVFILES = $(CONNECTALDIR)/lib/bsv/Strstr.bsv Top.bsv
CPPFILES=teststrstr.cpp
CONNECTALFLAGS += -D DEGPAR=8
CONNECTALFLAGS += -D HAYSTACKREADCLIENTS=1

include $(CONNECTALDIR)/Makefile.connectal
