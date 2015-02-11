
CONNECTALDIR?=../..
INTERFACES = SwallowRequest EchoRequest EchoIndication
BSVFILES = Echo.bsv Swallow.bsv
CPPFILES=testecho.cpp
CPPFILES2=daemon.cpp

NUMBER_OF_MASTERS =0

AUTOTOP = -l Echo.leds -w EchoRequest:Echo.request -w SwallowRequest:Swallow.request -p EchoIndication:Echo

include $(CONNECTALDIR)/Makefile.connectal
