
CONNECTALDIR?=../..
BSVFILES = Simple.bsv
CPPFILES=testsimple.cpp
NUMBER_OF_MASTERS =0

ifeq ($(BOARD),xsim)
S2H_INTERFACES = SimpleRequest:Simple.request
H2S_INTERFACES = Simple:SimpleRequest
AUTOTOP = --bluenoc
else
INTERFACES = SimpleRequest
BSVFILES += Top.bsv
endif

include $(CONNECTALDIR)/Makefile.connectal
