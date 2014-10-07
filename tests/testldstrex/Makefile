
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

MMDIR=../../examples/matmul
RBMDIR=../../examples/rbm
DBNTOPBSV=    Top.bsv
TESTCPPFILES= testldstrex.cpp
XBSVFLAGS = -D J_VALUE=2 -D K_VALUE=2 -D N_VALUE=2
XBSVFLAGS += -I /scratch/android-ndk-r9d/sources/cxx-stl/gnu-libstdc++/4.6/include
XBSVFLAGS += -I /scratch/android-ndk-r9d/sources/cxx-stl/gnu-libstdc++/4.6/libs/armeabi-v7a/include

include $(MMDIR)/Makefile.mm
S2H        =  TimerRequest
H2S        =  TimerIndication
CPPFILES   =  $(TESTCPPFILES)
NUMBER_OF_MASTERS=1
include ../../Makefile.connectal
