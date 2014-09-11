
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

GPU_PERF_TEST = 1

MMDIR=../../examples/matmul
RBMDIR=../../examples/rbm
DBNTOPBSV=    $(MMDIR)/Top.bsv
TESTCPPFILES= $(MMDIR)/testmm.cpp
XBSVFLAGS = -D J_VALUE=2 -D K_VALUE=2 -D N_VALUE=2

include $(MMDIR)/Makefile.mm
include ../../Makefile.xbsv
