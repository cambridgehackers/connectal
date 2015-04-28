
CONNECTALDIR?=../..
S2H_INTERFACES = InnerProdRequest:InnerProd.request
H2S_INTERFACES = InnerProd:InnerProdIndication

BSVFILES = InnerProdInterface.bsv
CPPFILES=testinnerprod.cpp
NUMBER_OF_MASTERS =0
AUTOTOP = --importfiles InnerProdInterface

DERIVED_CLOCK_PERIOD=2

CONNECTALFLAGS += -D IMPORT_HOSTIF -D BSV_POSITIVE_RESET
CONNECTALFLAGS += -P mkInnerProdTile

include $(CONNECTALDIR)/Makefile.connectal
