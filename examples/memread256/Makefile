CONNECTALDIR?=../..
S2H_INTERFACES = ReadTestRequest:ReadTest.request
H2S_INTERFACES = ReadTest:ReadTestIndication
MEM_READ_INTERFACES = lReadTest.dmaClient

BSVFILES = ../memread/ReadTest.bsv
CPPFILES= ../memread/testmemread.cpp
CONNECTALFLAGS += -D DataBusWidth=256
CONNECTALFLAGS += --mainclockperiod=8 -D USE_WIDE_WIDTH

include $(CONNECTALDIR)/Makefile.connectal
