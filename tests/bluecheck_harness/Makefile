CONNECTALDIR?=../..
S2H_INTERFACES = HarnessRequest:Harness.request
H2S_INTERFACES = Harness:HarnessResponse

BSVFILES = Harness.bsv
PYFILES  = physmemrequest.py

CONNECTALFLAGS += -D BLUECHECK --bsvpath=$(CONNECTALDIR)/../bluecheck

include $(CONNECTALDIR)/Makefile.connectal

