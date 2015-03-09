
CONNECTALDIR?=../..
INTERFACES = MaxcommonsubseqRequest MaxcommonsubseqIndication
BSVFILES = Maxcommonsubseq.bsv Top.bsv $(CONNECTALDIR)/lib/deprecated/DmaUtils.bsv
CPPFILES=testmaxcommonsubseq.cpp
CONNECTALFLAGS += -I $(CONNECTALDIR)/lib/strstr/cpp

include $(CONNECTALDIR)/Makefile.connectal
