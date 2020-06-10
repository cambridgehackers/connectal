CONNECTALDIR?=../..
S2H_INTERFACES = BscanRequest:BscanIF.request:host
H2S_INTERFACES = BscanIF:BscanIndication:host

BSVFILES = BscanIF.bsv
CPPFILES=testbscan.cpp
CONNECTALFLAGS += -D IMPORT_HOSTIF

include $(CONNECTALDIR)/Makefile.connectal

