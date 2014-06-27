
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

XBSVDIR=../..
DBNDIR=../testmm
DBNTOPBSV=     Top.bsv
TESTCPPFILES=  testfpmul.cpp
XBSVFLAGS = -D J_VALUE=2 -D K_VALUE=2 -D N_VALUE=2 
XBSVFLAGS += --bscflags " -D NumberOfMasters=0"
include $(DBNDIR)/Makefile.dbn
