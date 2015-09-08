CONNECTALDIR?=../..
S2H_INTERFACES = ReadTestRequest:ReadTest.request
H2S_INTERFACES = ReadTest:ReadTestIndication
MEM_READ_INTERFACES = lReadTest.dmaClient

BSVFILES = ../memread/ReadTest.bsv
CPPFILES= ../memread/testmemread.cpp
CONNECTALFLAGS += -D DataBusWidth=128

include $(CONNECTALDIR)/Makefile.connectal
