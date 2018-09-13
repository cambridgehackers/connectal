CONNECTALDIR?=../..
S2H_INTERFACES = PcieMemCheckRequest:PcieMemCheck.request
H2S_INTERFACES = PcieMemCheck:PcieMemCheckIndication

BSVFILES = PcieMemCheck.bsv 
CPPFILES = pciememcheck.cpp
CONNECTALFLAGS += -D USE_ACP -P mkConnectalTop

include $(CONNECTALDIR)/Makefile.connectal
