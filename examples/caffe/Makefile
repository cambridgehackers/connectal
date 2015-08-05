CONNECTALDIR?=../..
#INTERFACES = EchoRequest EchoIndication

#BSVFILES = Echo.bsv Top.bsv
CPPFILES = $(CONNECTALDIR)/lib/cpp/connectal_conv.cpp
CONNECTALFLAGS += --shared
CONNECTALFLAGS += --nohardware
NUMBER_OF_MASTERS =0

include $(CONNECTALDIR)/Makefile.connectal

