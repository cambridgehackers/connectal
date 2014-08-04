
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

XBSVDIR=../..
DBNDIR=../matmul
DBNTOPBSV=Top.bsv
TESTCPPFILES=testmm.cpp
XBSVFLAGS = -D J_VALUE=1 -D K_VALUE=1 -D N_VALUE=1 -D DataBusWidth=32

include ../matmul/Makefile.dbn
