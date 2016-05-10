CONNECTALDIR?=../..
S2H_INTERFACES = RegexpRequest:Regexp.request
H2S_INTERFACES = Regexp\#\(64\):RegexpIndication
MEM_READ_INTERFACES = "append(lRegexp.config_read_client,lRegexp.haystack_read_client)"

BSVFILES = $(CONNECTALDIR)/lib/regexp/bsv/Regexp.bsv
CPPFILES=testregexp.cpp
CONNECTALFLAGS = -D DEGPAR=4 -D MAX_NUM_STATES=32 -D MAX_NUM_CHARS=32 
CONNECTALFLAGS += --stl=gnustl_static
RUN_ARGS = test.bin
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/regexp/cpp
CONNECTALFLAGS += --run-args="$(addprefix $(PWD)/, jregexp.charMap jregexp.stateMap jregexp.stateTransitions test.bin)"
include $(CONNECTALDIR)/Makefile.connectal
