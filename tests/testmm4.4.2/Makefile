
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

XBSVDIR=../..
DBNDIR=../../examples/testmm
DBNTOPBSV=    $(DBNDIR)/Top.bsv
TESTCPPFILES= $(DBNDIR)/testmm.cpp
XBSVFLAGS = -D J_VALUE=4 -D K_VALUE=4 -D N_VALUE=2
XBSVFLAGS += -D IMPORT_HOSTIF

include $(DBNDIR)/Makefile.dbn
