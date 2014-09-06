
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

MMDIR=../matmul
RBMDIR=../rbm
DBNTOPBSV=Top.bsv
TESTCPPFILES=testmm.cpp
XBSVFLAGS = -D J_VALUE=1 -D K_VALUE=1 -D N_VALUE=1 -D DataBusWidth=32

include $(MMDIR)/Makefile.mm
include ../../Makefile.xbsv
