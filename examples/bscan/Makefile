
CONNECTALDIR?=../..
INTERFACES = BscanRequest BscanIndication
BSVFILES = BscanIF.bsv Top.bsv
CPPFILES=testbscan.cpp
NUMBER_OF_MASTERS =0
CONNECTALFLAGS += --bscflags " -D USES_BSCAN"
# CONNECTALFLAGS += --bscflags " -D TRACE_AXI"

include $(CONNECTALDIR)/Makefile.connectal

