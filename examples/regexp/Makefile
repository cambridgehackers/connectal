
CONNECTALDIR?=../..
INTERFACES = RegexpRequest RegexpIndication
BSVFILES = $(CONNECTALDIR)/lib/regexp/bsv/Regexp.bsv Top.bsv
CPPFILES=testregexp.cpp
CONNECTALFLAGS = -D DEGPAR=4 -D MAX_NUM_STATES=32 -D MAX_NUM_CHARS=32 
RUN_ARGS = test.bin
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/regexp/cpp


include $(CONNECTALDIR)/Makefile.connectal
