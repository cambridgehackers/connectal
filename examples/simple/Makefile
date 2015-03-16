
CONNECTALDIR?=../..
S2H_INTERFACES = SimpleRequest:Simple.request
H2S_INTERFACES = Simple:SimpleRequest
BSVFILES = Simple.bsv
CPPFILES=testsimple.cpp
NUMBER_OF_MASTERS =0

ifeq ($(BOARD), $(filter $(BOARD), de5 htg4))
PIN_BINDINGS?=-b PCIE:PCIE -b LED:LED -b OSC:OSC
endif

include $(CONNECTALDIR)/Makefile.connectal
