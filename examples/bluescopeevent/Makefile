
CONNECTALDIR?=../..
INTERFACES = SerialConfigRequest SerialConfigIndication \
	BlueScopeEventRequest BlueScopeEventIndication
BSVFILES = $(CONNECTALDIR)/lib/bsv/BlueScopeEvent.bsv Top.bsv
CPPFILES=testbluescopeevent.cpp
#CONNECTALFLAGS=--bscflags " -D TRACE_AXI"

include $(CONNECTALDIR)/Makefile.connectal
