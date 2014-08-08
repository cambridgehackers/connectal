
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

XBSVDIR=../..
MMDIR=../../examples/matmul
RBMDIR=../../examples/rbm
DBNTOPBSV=$(MMDIR)/Top.bsv
TESTCPPFILES=$(MMDIR)/testmm.cpp
XBSVFLAGS = -D J_VALUE=32 -D K_VALUE=16 -D N_VALUE=2

include $(MMDIR)/Makefile.mm
include $(XBSVDIR)/Makefile.xbsv
