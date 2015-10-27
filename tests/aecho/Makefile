CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication

BSVFILES = Echo.bsv
CPPFILES= testecho.cpp
CONNECTALFLAGS += --verilog $(CONNECTALDIR)/../llvm-translate/generated

include $(CONNECTALDIR)/Makefile.connectal
