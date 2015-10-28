CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication

GENDIR = $(CONNECTALDIR)/../llvm-translate/generated
BSVFILES = Echo.bsv
CPPFILES = testecho.cpp
CONNECTALFLAGS += --verilog $(GENDIR) --bsvpath $(GENDIR)

include $(CONNECTALDIR)/Makefile.connectal
