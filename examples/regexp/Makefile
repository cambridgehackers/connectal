
CONNECTALDIR?=../..
S2H_INTERFACES = RegexpRequest:Regexp.request
H2S_INTERFACES = Regexp:RegexpIndication::64
MEM_INTERFACES = "cons(lRegexp.config_read_client,cons(lRegexp.haystack_read_client,nil)),nil"

BSVFILES = $(CONNECTALDIR)/lib/regexp/bsv/Regexp.bsv
CPPFILES=testregexp.cpp
CONNECTALFLAGS = -D DEGPAR=4 -D MAX_NUM_STATES=32 -D MAX_NUM_CHARS=32 
RUN_ARGS = test.bin
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/regexp/cpp

include $(CONNECTALDIR)/Makefile.connectal
