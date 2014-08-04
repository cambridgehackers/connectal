
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

XBSVDIR=../..
DBNDIR=../../examples/matmul
DBNTOPBSV=    $(DBNDIR)/Top.bsv
TESTCPPFILES= $(DBNDIR)/testmm.cpp
XBSVFLAGS = -D J_VALUE=2 -D K_VALUE=4 -D N_VALUE=2
include $(DBNDIR)/Makefile.dbn
