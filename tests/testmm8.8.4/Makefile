
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

MMDIR=../../examples/matmul
RBMDIR=../../examples/rbm
DBNTOPBSV=    $(MMDIR)/Top.bsv
TESTCPPFILES= $(MMDIR)/testmm.cpp
CONNECTALFLAGS = -D J_VALUE=8 -D K_VALUE=8 -D N_VALUE=4 -D DataBusWidth=128

include $(MMDIR)/Makefile.mm
include ../../Makefile.connectal
