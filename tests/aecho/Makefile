CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication

LLVMT = $(CONNECTALDIR)/../llvm-translate/Debug+Asserts/bin/llvm-translate
ACCDIR = $(CONNECTALDIR)/../atomicc/examples/echo
GENDIR = generated
BSVFILES = EchoReq.bsv
CPPFILES = testecho.cpp
CONNECTALFLAGS += --verilog $(GENDIR) --bsvpath $(GENDIR)
CONNECTALFLAGS += --verilog .
BSCFLAGS += -show-bvi
AUTOTOP += --integratedIndication

prebuild::
	$(LLVMT) --odir=$(GENDIR) $(ACCDIR)/echo.ll $(ACCDIR)/atomicc.ll

include $(CONNECTALDIR)/Makefile.connectal
