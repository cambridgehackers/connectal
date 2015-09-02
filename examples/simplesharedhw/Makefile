
CONNECTALDIR?=../..
INTERFACES = SharedMemoryPortalConfig
S2H_INTERFACES = /SimpleRequest:Simple.request
H2S_INTERFACES = /Simple:SimpleRequest
MEM_INTERFACES = "cons(lSharereadEngine.dmaClient,nil),cons(lSharewriteEngine.dmaClient,nil)"

CONNECTALFLAGS += -D USE_ACP
BSVFILES = Simple.bsv $(CONNECTALDIR)/bsv/Portal.bsv
CPPFILES=testsimple.cpp $(CONNECTALDIR)/cpp/transportShared.c
AUTOTOP = --importfiles SharedMemoryPortal --importfiles SharedMemoryPortalConfig --importfiles MemTypes --importfiles MemreadEngine --importfiles MemwriteEngine

include $(CONNECTALDIR)/Makefile.connectal
