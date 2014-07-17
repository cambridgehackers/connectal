
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

XBSVDIR=../..
DBNDIR=../testmm
DBNTOPBSV=Top.bsv
TESTCPPFILES=testmm.cpp
XBSVFLAGS = -l opencv_core
NUMBER_OF_MASTERS =1
XBSVFLAGS += -D DataBusWidth=32
XBSVFLAGS += -D IMPORT_HOSTIF

##USE_PRINTF = 1
include ../testmm/Makefile.dbn
