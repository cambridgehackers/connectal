CONNECTALDIR?=../..
S2H_INTERFACES = ReadTestRequest:ReadTest.request
H2S_INTERFACES = ReadTest\#\(\`NumberOfMasters\):ReadTestIndication
MEM_READ_INTERFACES = lReadTest.dmaClients

BSVFILES = ReadTest.bsv
CPPFILES=../memread/testmemread.cpp
PLATFORM_NUMBER_OF_MASTERS =4
#CONNECTALFLAGS += -I$(CONNECTALDIR)/examples/memread

include $(CONNECTALDIR)/Makefile.connectal
