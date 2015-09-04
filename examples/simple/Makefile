CONNECTALDIR?=../..
S2H_INTERFACES = SimpleRequest:Simple.request
H2S_INTERFACES = Simple:SimpleRequest

BSVFILES = Simple.bsv
CPPFILES = testsimple.cpp

ifeq ($(BOARD), $(filter $(BOARD), de5 htg4))
PIN_BINDINGS?=PCIE:PCIE LED:LED OSC:OSC
endif

include $(CONNECTALDIR)/Makefile.connectal
