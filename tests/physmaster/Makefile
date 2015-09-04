CONNECTALDIR?=../..
INTERFACES = EchoRequest EchoIndication PhysMemMasterRequest PhysMemMasterIndication

BSVFILES = Echo.bsv PhysReq.bsv
CPPFILES=daemon.cpp
CPPFILES2=testecho.cpp
CONNECTALFLAGS += --nohardware
AUTOTOP= --portname IfcNames_PhysMemMasterIndication --portname IfcNames_PhysMemMasterRequest

include $(CONNECTALDIR)/Makefile.connectal
