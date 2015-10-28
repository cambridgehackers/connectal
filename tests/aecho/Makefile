CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication

LLVMT = $(CONNECTALDIR)/../llvm-translate/Debug+Asserts/bin/llvm-translate
ACCDIR = $(CONNECTALDIR)/../atomicc/examples/echo_new
GENDIR = generated
BSVFILES = Echo.bsv
CPPFILES = testecho.cpp
CONNECTALFLAGS += --verilog $(GENDIR) --bsvpath $(GENDIR)

prebuild::
	$(LLVMT) --odir=$(GENDIR) $(ACCDIR)/echo.ll $(ACCDIR)/atomicc.ll

include $(CONNECTALDIR)/Makefile.connectal
