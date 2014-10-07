
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

CUDA_PERF_TEST = 1

MMDIR=../../examples/matmul
RBMDIR=../../examples/rbm
DBNTOPBSV=    $(MMDIR)/Top.bsv
TESTCPPFILES= $(MMDIR)/testmm.cpp
XBSVFLAGS = -D J_VALUE=8 -D K_VALUE=8 -D N_VALUE=2
XBSVFLAGS += -D CUDA_PERF_TEST=$(CUDA_PERF_TEST)

include $(MMDIR)/Makefile.mm
include ../../Makefile.connectal
