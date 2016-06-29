CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoResponse

BSVFILES = EchoInterface.bsv
PYFILES  = testecho.py

CONNECTALFLAGS += --run-args="$(PWD)/testecho.py $(CONNECTALDIR)/scripts/portal.py $(PWD)/$(BOARD)/bin/connectal.so"
CONNECTALFLAGS += -D PYTHONPATH=$(CONNECTALDIR)/scripts:.

include $(CONNECTALDIR)/Makefile.connectal
