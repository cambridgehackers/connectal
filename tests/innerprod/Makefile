
CONNECTALDIR?=../..
S2H_INTERFACES = InnerProdRequest:InnerProd.request
H2S_INTERFACES = InnerProd:InnerProdIndication

BSVFILES = InnerProdInterface.bsv
CPPFILES=testinnerprod.cpp
NUMBER_OF_MASTERS =0
AUTOTOP = --importfiles InnerProdInterface

DERIVED_CLOCK_PERIOD=5
CONNECTALFLAGS += -D IMPORT_HOSTIF

#CONNECTALFLAGS += -P mkInnerProdTile
CONNECTALFLAGS += -P mkMacroTile
#CONNECTALFLAGS += -P mkRequestPipes -P mkResponsePipes
CONNECTALFLAGS += -P mkRequestPipesSynth -P mkResponsePipesSynth 
#CONNECTALFLAGS += -P mkRequestPipesMTSynth -P mkResponsePipesMTSynth

ifeq ($(BOARD),xsim)
AUTOTOP = --bluenoc
endif

xsim_manual:
	make build.xsim
	cd xsim; xvlog --sv ../xsimtop.sv
	cd xsim; xsc -v -cc -gcc -compile ../xsimtop.c
	cd xsim; xelab -cc gcc -svlog ../xsimtop.sv --debug wave -L unisim -L unifast work.xsimtop -sv_lib xsimtop.lnx64.o
	cd xsim; xsim -g work.xsimtop

include $(CONNECTALDIR)/Makefile.connectal
