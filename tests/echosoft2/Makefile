CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:EchoId.request SwallowRequest:Swallow.request
H2S_INTERFACES = EchoId:EchoIndication

BSVFILES = EchoId.bsv ../../examples/echosoft/Swallow.bsv
CPPFILES=testecho.cpp
CPPFILES2=daemon.cpp
AUTOTOP = --portname IfcNames_EchoIndication2H2S --portname IfcNames_EchoRequest2S2H

include $(CONNECTALDIR)/Makefile.connectal
