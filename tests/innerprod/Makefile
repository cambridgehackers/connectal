
CONNECTALDIR?=../..
S2H_INTERFACES = InnerProdRequest:InnerProd.request
H2S_INTERFACES = InnerProd:InnerProdIndication

BSVFILES = InnerProdInterface.bsv
CPPFILES=testinnerprod.cpp
NUMBER_OF_MASTERS =0
AUTOTOP = --importfiles InnerProdInterface

#DERIVED_CLOCK_PERIOD=2

#CONNECTALFLAGS += -D IMPORT_HOSTIF
CONNECTALFLAGS += -P mkInnerProdTile

ifeq ($(BOARD),xsim)
AUTOTOP = --bluenoc
endif

xsim_manual:
	make build.xsim
	cd xsim; xvlog --sv ../xsimtop.sv
	cd xsim; xelab --debug wave -L unisim -L unifast work.xsimtop
	cd xsim; xsim work.xsimtop

include $(CONNECTALDIR)/Makefile.connectal
