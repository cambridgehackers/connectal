CONNECTALDIR?=../..
INTERFACES = SharedMemoryPortalConfig
S2H_INTERFACES = /SimpleRequest:Simple.request
H2S_INTERFACES = /Simple:SimpleRequest
MEM_READ_INTERFACES = "cons(lSharereadEngine.dmaClient,nil)"
MEM_WRITE_INTERFACES = "cons(lSharewriteEngine.dmaClient,nil)"

CONNECTALFLAGS += -D USE_ACP
BSVFILES = Simple.bsv $(CONNECTALDIR)/bsv/Portal.bsv
CPPFILES=testsimple.cpp $(CONNECTALDIR)/cpp/transportShared.c
CONNECTALFLAGS += -D USE_ACP
AUTOTOP = --importfiles SharedMemoryPortal --importfiles SharedMemoryPortalConfig --importfiles MemTypes --importfiles MemReadEngine --importfiles MemWriteEngine

include $(CONNECTALDIR)/Makefile.connectal
