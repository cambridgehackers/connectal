CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request SwallowRequest:Swallow.request
H2S_INTERFACES = Echo:EchoIndication

BSVFILES = Echo.bsv Swallow.bsv
CPPFILES=testecho.cpp $(CONNECTALDIR)/cpp/portalWebSocket.c
CPPFILES2=daemon.cpp $(CONNECTALDIR)/cpp/portalWebSocket.c
CONNECTALFLAGS += -lwebsockets

include $(CONNECTALDIR)/Makefile.connectal
