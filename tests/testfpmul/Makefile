CONNECTALDIR?=../..

MMDIR=../../examples/matmul
TESTCPPFILES=  testfpmul.cpp
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib
CONNECTALFLAGS = -D J_VALUE=2 -D K_VALUE=2 -D N_VALUE=2

include $(MMDIR)/Makefile.mm
include $(MMDIR)/Makefile.mmif
include $(CONNECTALDIR)/Makefile.connectal
