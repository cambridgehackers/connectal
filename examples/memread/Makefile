
CONNECTALDIR?=../..
S2H_INTERFACES = ReadTestRequest:ReadTest.request
H2S_INTERFACES = ReadTest:ReadTestIndication
MEM_READ_INTERFACES = lReadTest.dmaClient
BSVFILES = ReadTest.bsv
CPPFILES=testmemread.cpp

ifeq ($(BOARD),zedboard)
CONNECTALFLAGS += -DBSV_POSITIVE_RESET
endif
ifeq ($(BOARD),xsim)
CONNECTALFLAGS += -DBSV_POSITIVE_RESET
endif

#CONNECTALFLAGS += -DTLP32
CONNECTALFLAGS += -DMEMENGINE_REQUEST_CYCLES

include $(CONNECTALDIR)/Makefile.connectal
