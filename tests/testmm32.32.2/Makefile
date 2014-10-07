
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

MMDIR=../../examples/matmul
RBMDIR=../../examples/rbm
DBNTOPBSV=    $(MMDIR)/Top.bsv
TESTCPPFILES= $(MMDIR)/testmm.cpp
CONNECTALFLAGS = -D J_VALUE=32 -D K_VALUE=32 -D N_VALUE=2

include $(MMDIR)/Makefile.mm
include ../../Makefile.connectal
