CONNECTALDIR?=../..
S2H_INTERFACES = ReadTestRequest:ReadTest.request
H2S_INTERFACES = ReadTest\#\(\`NumEngines\):ReadTestIndication
MEM_READ_INTERFACES = lReadTest.dmaClients

BSVFILES = ReadTest.bsv
CPPFILES = ../../examples/memread/testmemread.cpp
CONNECTALFLAGS += --bscflags " -D DataBusWidth=128 -D NumEngines=4"
CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memread

include $(CONNECTALDIR)/Makefile.connectal

