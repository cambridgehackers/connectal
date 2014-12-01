
CONNECTALDIR?=../..
INTERFACES = MemcpyRequest BlueScopeRequest MemcpyIndication BlueScopeIndication MemServerIndication
BSVFILES = Memcpy.bsv $(CONNECTALDIR)/lib/bsv/BlueScope.bsv Top.bsv
CPPFILES=testbluescope.cpp
#CONNECTALFLAGS=--bscflags " -D TRACE_AXI"

include $(CONNECTALDIR)/Makefile.connectal
