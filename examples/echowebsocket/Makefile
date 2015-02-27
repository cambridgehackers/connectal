
CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request SwallowRequest:Swallow.request
H2S_INTERFACES = EchoIndication:Echo
BSVFILES = Echo.bsv Swallow.bsv
CONNECTALFLAGS += -lwebsockets
CPPFILES=daemon.cpp $(CONNECTALDIR)/cpp/portalWebSocket.c
#CPPFILES2=testecho.cpp

NUMBER_OF_MASTERS =0

AUTOTOP = --interface leds:Echo.leds

include $(CONNECTALDIR)/Makefile.connectal
