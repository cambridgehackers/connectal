
CONNECTALDIR?=../..
INTERFACES = EchoRequest EchoIndication
# PhysMemMasterRequest PhysMemMasterIndication
BSVFILES = Echo.bsv Top.bsv $(CONNECTALDIR)/bsv/MemTypes.bsv
CPPFILES=daemon.cpp
CPPFILES2=testecho.cpp

NUMBER_OF_MASTERS =0

include $(CONNECTALDIR)/Makefile.connectal
