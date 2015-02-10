
CONNECTALDIR?=../..
INTERFACES = SimpleRequest
BSVFILES = Simple.bsv
CPPFILES=testsimple.cpp
NUMBER_OF_MASTERS =0

AUTOTOP = -w SimpleRequest:Simple -y SimpleRequest:Simple

ifeq ($(BOARD),de5)
ALTERA_de5=1
PIN_BINDINGS?=-b PCIE:PCIE -b LED:LED -b OSC:OSC

gentarget:: $(BOARD)/sources/altera.qsf
endif

$(BOARD)/sources/altera.qsf: altera.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
ifeq ($(ALTERA_$(BOARD)), 1)
	mkdir -p $(BOARD)/sources
	$(CONNECTALDIR)/scripts/generate-constraints.py -f altera $(PIN_BINDINGS) -o $(BOARD)/sources/$(BOARD).qsf $(CONNECTALDIR)/boardinfo/$(BOARD).json altera.json
endif

include $(CONNECTALDIR)/Makefile.connectal
