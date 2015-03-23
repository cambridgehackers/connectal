
CONNECTALDIR?=../..
S2H_INTERFACES = MainRequest:Main.request
H2S_INTERFACES = Main:MainRequest
BSVFILES = Main.bsv RegFile.bsv
CPPFILES=testmain.cpp
NUMBER_OF_MASTERS =0

include $(CONNECTALDIR)/Makefile.connectal


RegFile.bsv: regfile.v
	$(CONNECTALDIR)/generated/scripts/importbvi.py -o RegFile.bsv -I RegFile -P RF regfile.v
