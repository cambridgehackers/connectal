CONNECTALDIR?=../..
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

MMDIR=../../examples/matmul
TESTCPPFILES=  testfpmul.cpp
CONNECTALFLAGS = -D J_VALUE=2 -D K_VALUE=2 -D N_VALUE=2
NUMBER_OF_MASTERS =0

include $(MMDIR)/Makefile.mm
include $(MMDIR)/Makefile.mmif
include $(CONNECTALDIR)/Makefile.connectal
