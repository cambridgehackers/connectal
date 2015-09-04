CONNECTALDIR?=../..
S2H_INTERFACES = MainRequest:Main.request
H2S_INTERFACES = Main:MainRequest

BSVFILES = Main.bsv RegFile.bsv
CPPFILES=testmain.cpp

RegFile.bsv: regfile.v
	$(CONNECTALDIR)/generated/scripts/importbvi.py -o RegFile.bsv -I RegFile -P RF  -c clock -r reset_n \
	regfile.v

include $(CONNECTALDIR)/Makefile.connectal
