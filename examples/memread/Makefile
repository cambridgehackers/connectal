
CONNECTALDIR?=../..
S2H_INTERFACES = ReadTestRequest:ReadTest.request
H2S_INTERFACES = ReadTest:ReadTestIndication
MEM_INTERFACES = lReadTest.dmaClient,nil
BSVFILES = ReadTest.bsv
CPPFILES=testmemread.cpp

ifeq ($(BOARD),zedboard)
CONNECTALFLAGS += -DBSV_POSITIVE_RESET
endif
ifeq ($(BOARD),xsim)
CONNECTALFLAGS += -DBSV_POSITIVE_RESET
endif

include $(CONNECTALDIR)/Makefile.connectal
