CONNECTALDIR?=../..
S2H_INTERFACES = SimpleRequest:Simple.request
H2S_INTERFACES = Simple:SimpleRequest

BSVFILES = Simple.bsv
#original user program CPPFILES=testsimple.cpp
CPPFILES=simple_manual.c
CONNECTALFLAGS += -D NO_CPP_PORTAL_CODE

include $(CONNECTALDIR)/Makefile.connectal
