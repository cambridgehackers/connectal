
CONNECTALDIR?=../..
#INTERFACES = SimpleRequest MMURequest MMUIndication MemServerRequest MemServerIndication SharedMemoryPortalConfig
INTERFACES = SharedMemoryPortalConfig
S2H_INTERFACES = /SimpleRequest:Simple.request
H2S_INTERFACES = /Simple:SimpleRequest
MEM_INTERFACES = "append(lSimpleRequestWrapperShare.readClient,lSimpleRequestProxyShare.readClient),append(lSimpleRequestWrapperShare.writeClient,lSimpleRequestProxyShare.writeClient)"

BSVFILES = Simple.bsv
#BSVFILES += Top.bsv
CPPFILES=testsimple.cpp $(CONNECTALDIR)/cpp/portalShared.c
AUTOTOP = --importfiles SharedMemoryPortal --importfiles SharedMemoryPortalConfig

include $(CONNECTALDIR)/Makefile.connectal
