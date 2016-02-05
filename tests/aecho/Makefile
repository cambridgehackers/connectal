CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication

LTDIR = $(CONNECTALDIR)/../llvm-translate/
LLVMT = $(LTDIR)/Debug+Asserts/bin/llvm-translate
ACCDIR = $(CONNECTALDIR)/../atomicc/examples/echo
GENDIR = generated
BSVFILES = EchoReq.bsv
CPPFILES = testecho.cpp
CONNECTALFLAGS += --verilog $(GENDIR) --bsvpath $(GENDIR)
BSCFLAGS += -show-bvi
AUTOTOP += --integratedIndication

prebuild::
	$(LLVMT) --odir=$(GENDIR) $(ACCDIR)/fifo.ll
	$(LLVMT) --odir=$(GENDIR) $(ACCDIR)/echo.ll $(ACCDIR)/atomicc.ll
	$(LTDIR)/linker.py --directory generated --output Echo l_class_OC_Echo

include $(CONNECTALDIR)/Makefile.connectal
