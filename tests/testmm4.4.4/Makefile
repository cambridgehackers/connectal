
CONNECTALDIR?=../..
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

MMDIR=$(CONNECTALDIR)/examples/matmul
RBMDIR=$(CONNECTALDIR)/examples/rbm
DBNTOPBSV=    $(MMDIR)/Top.bsv
TESTCPPFILES= $(MMDIR)/testmm.cpp
CONNECTALFLAGS = -D J_VALUE=4 -D K_VALUE=4 -D N_VALUE=4 -D DataBusWidth=128

include $(MMDIR)/Makefile.mm
include $(CONNECTALDIR)/Makefile.connectal
