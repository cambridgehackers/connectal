
CONNECTALDIR?=../..
INTERFACES = SwallowRequest EchoRequest EchoIndication
#INTERFACES += MMURequest MMUIndication
## all the BSV files to be scanned for types and interfaces
BSVFILES = Echo.bsv Swallow.bsv
#BSVFILES += $(CONNECTALDIR)/bsv/ConnectalMemory.bsv
## the source files in the example
CPPFILES=testecho.cpp
CPPFILES2=daemon.cpp

NUMBER_OF_MASTERS =0

AUTOTOP = -l Echo -w EchoRequest:Echo -w SwallowRequest:Swallow -y EchoIndication:Echo
#AUTOTOP += -w MMURequest:MMU -y MMUIndication:MMU

include $(CONNECTALDIR)/Makefile.connectal
