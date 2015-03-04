
CONNECTALDIR?=../..
INTERFACES = Swallow EchoRequest EchoIndication MMURequest MMUIndication
BSVFILES = Echo.bsv SwallowIF.bsv Top.bsv
BSVFILES += $(CONNECTALDIR)/bsv/ConnectalMemory.bsv
CPPFILES=testecho.cpp
CPPFILES2=daemon.cpp

NUMBER_OF_MASTERS =0

include $(CONNECTALDIR)/Makefile.connectal
