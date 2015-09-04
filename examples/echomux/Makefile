CONNECTALDIR?=../..
INTERFACES = EchoRequestSW EchoIndicationSW SecondRequest SecondIndication ThirdRequest ThirdIndication
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication

BSVFILES = Echo.bsv Services.bsv
CPPFILES=testecho.cpp
CPPFILES2=daemon.cpp
AUTOTOP = --portname IfcNames_SecondRequest --portname IfcNames_SecondIndication --portname IfcNames_ThirdRequest --portname IfcNames_ThirdIndication

include $(CONNECTALDIR)/Makefile.connectal
