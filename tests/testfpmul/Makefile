
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

XBSVDIR=../..
DBNDIR=../../examples/matmul
DBNTOPBSV=     Top.bsv
TESTCPPFILES=  testfpmul.cpp
XBSVFLAGS = -D J_VALUE=2 -D K_VALUE=2 -D N_VALUE=2
NUMBER_OF_MASTERS =0
include $(DBNDIR)/Makefile.dbn
