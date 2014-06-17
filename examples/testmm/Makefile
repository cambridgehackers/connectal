
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

XBSVDIR=../..
DBNDIR=../testmm
DBNTOPBSV=Top.bsv
TESTCPPFILES=testmm.cpp
XBSVFLAGS = -l opencv_core
XBSVFLAGS += -D NumberOfMasters=1
##USE_PRINTF = 1
include ../testmm/Makefile.dbn
