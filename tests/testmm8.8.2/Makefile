
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

XBSVDIR=$(shell cd ../..; /bin/pwd)
DBNDIR=../../examples/matmul
DBNTOPBSV=    $(DBNDIR)/Top.bsv
TESTCPPFILES= $(DBNDIR)/testmm.cpp
XBSVFLAGS = -D J_VALUE=8 -D K_VALUE=8 -D N_VALUE=2
include $(DBNDIR)/Makefile.dbn

