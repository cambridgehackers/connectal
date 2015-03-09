
CONNECTALDIR?=../..
INTERFACES = EchoRequestSW EchoIndicationSW SecondRequest SecondIndication ThirdRequest ThirdIndication
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = EchoIndication:Echo
BSVFILES = Echo.bsv Services.bsv
CPPFILES=testecho.cpp
CPPFILES2=daemon.cpp

NUMBER_OF_MASTERS =0
AUTOTOP = --portname SecondRequest --portname SecondIndication --portname ThirdRequest --portname ThirdIndication

include $(CONNECTALDIR)/Makefile.connectal
