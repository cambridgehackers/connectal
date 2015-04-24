
CONNECTALDIR?=../..
INTERFACES = SharedMemoryPortalConfig
S2H_INTERFACES = /SimpleRequest:Simple.request
H2S_INTERFACES = /Simple:SimpleRequest
MEM_INTERFACES = "cons(lSharereadEngine.dmaClient,nil),cons(lSharewriteEngine.dmaClient,nil)"

BSVFILES = Simple.bsv $(CONNECTALDIR)/bsv/Portal.bsv
CPPFILES=testsimple.cpp $(CONNECTALDIR)/cpp/transportShared.c
AUTOTOP = --importfiles SharedMemoryPortal --importfiles SharedMemoryPortalConfig

include $(CONNECTALDIR)/Makefile.connectal
