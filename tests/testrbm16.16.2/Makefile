CONNECTALDIR?=../..
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

MMDIR=$(CONNECTALDIR)/examples/matmul
RBMDIR=$(CONNECTALDIR)/examples/rbm
TESTCPPFILES= $(RBMDIR)/testrbm.cpp
CONNECTALFLAGS = -D J_VALUE=16 -D K_VALUE=16 -D N_VALUE=2 -D DataBusWidth=64

include $(MMDIR)/Makefile.mm
include $(RBMDIR)/Makefile.rbm
include $(CONNECTALDIR)/Makefile.connectal

