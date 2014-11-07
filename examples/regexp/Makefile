
CONNECTALDIR?=../..
INTERFACES = RegexpRequest RegexpIndication
BSVFILES = Regexp.bsv Top.bsv
CPPFILES=testregexp.cpp
CONNECTALFLAGS = -D DEGPAR=4 -D MAX_NUM_STATES=32 -D MAX_NUM_CHARS=32 
RUN_ARGS = test.bin


include $(CONNECTALDIR)/Makefile.connectal
