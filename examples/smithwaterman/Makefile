
CONNECTALDIR?=../..
INTERFACES = SmithwatermanRequest SmithwatermanIndication
BSVFILES = Smithwaterman.bsv Top.bsv $(CONNECTALDIR)/lib/deprecated/DmaUtils.bsv
CPPFILES=testsmithwaterman.cpp
CONNECTALFLAGS += -I $(CONNECTALDIR)/lib/strstr/cpp

include $(CONNECTALDIR)/Makefile.connectal
