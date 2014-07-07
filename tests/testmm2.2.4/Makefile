
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

## absolute path to XBSV
XBSVDIR=$(shell cd ../..; /bin/pwd)
DBNDIR=../../examples/testmm
DBNTOPBSV=    $(DBNDIR)/Top.bsv
TESTCPPFILES= $(DBNDIR)/testmm.cpp
XBSVFLAGS = -D J_VALUE=2 -D K_VALUE=2 -D N_VALUE=4
include $(DBNDIR)/Makefile.dbn
