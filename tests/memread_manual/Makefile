
CONNECTALDIR?=../..
INTERFACES = RtestRequest RtestIndication
BSVFILES = Rtest.bsv Top.bsv
#CPPFILES=testmemread.cpp
#CPPFILES=memread_manual.cpp
CPPFILES=memread_manual_manager.c
CONNECTALFLAGS += -D NO_CPP_PORTAL_CODE -D NO_POLLER_SUPPORT

include $(CONNECTALDIR)/Makefile.connectal

