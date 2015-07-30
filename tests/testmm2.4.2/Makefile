CONNECTALDIR?=../..
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

MMDIR=$(CONNECTALDIR)/examples/matmul
RBMDIR=$(CONNECTALDIR)/examples/rbm
TESTCPPFILES= $(MMDIR)/testmm.cpp
CONNECTALFLAGS = -D J_VALUE=2 -D K_VALUE=4 -D N_VALUE=2

include $(MMDIR)/Makefile.mm
include $(MMDIR)/Makefile.mmif
include $(CONNECTALDIR)/Makefile.connectal
