
CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request SwallowRequest:Swallow.request
H2S_INTERFACES = Echo:EchoIndication
BSVFILES = Echo.bsv Swallow.bsv
CONNECTALFLAGS += -lwebsockets
CPPFILES=testecho.cpp $(CONNECTALDIR)/cpp/portalWebSocket.c
CPPFILES2=daemon.cpp $(CONNECTALDIR)/cpp/portalWebSocket.c

NUMBER_OF_MASTERS =0

include $(CONNECTALDIR)/Makefile.connectal
