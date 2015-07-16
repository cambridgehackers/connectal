
CONNECTALDIR?=../..
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

MMDIR=../matmul
RBMDIR=../rbm
TESTCPPFILES=testmm.cpp
CONNECTALFLAGS = -D J_VALUE=1 -D K_VALUE=1 -D N_VALUE=1 -D DataBusWidth=32

include $(MMDIR)/Makefile.mm
include $(MMDIR)/Makefile.mmif
include $(CONNECTALDIR)/Makefile.connectal
