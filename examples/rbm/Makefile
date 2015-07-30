CONNECTALDIR?=../..
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib
CONNECTALFLAGS = -D J_VALUE=1 -D K_VALUE=1 -D N_VALUE=1 -D DataBusWidth=32

MMDIR=../matmul
RBMDIR=../rbm
TESTCPPFILES= testrbm.cpp

include $(MMDIR)/Makefile.mm
include $(RBMDIR)/Makefile.rbm
include $(CONNECTALDIR)/Makefile.connectal
