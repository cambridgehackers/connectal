CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication

BSVFILES = Echo.bsv
CPPFILES= testecho.cpp
CONNECTALFLAGS += -V ./l_class_OC_Fifo1.v

#prebuild::
#	$(CONNECTALDIR)/generated/scripts/importbvi.py -I Clai -P Clap --o Clai.bsv $(CONNECTALDIR)/verilog/l_class_OC_Fifo1.v 

include $(CONNECTALDIR)/Makefile.connectal

