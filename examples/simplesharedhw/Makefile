
CONNECTALDIR?=../..
#INTERFACES = SimpleRequest MMURequest MMUIndication MemServerRequest MemServerIndication SharedMemoryPortalConfig
INTERFACES = SharedMemoryPortalConfig
S2H_INTERFACES = /SimpleRequest:Simple.request
H2S_INTERFACES = /Simple:SimpleRequest
MEM_INTERFACES = mkMemServerRW:cons\(lSimpleRequestWrapperPortalMem.readClient,cons\(lSimpleRequestProxyPortalMem.readClient,nil\)\),cons\(lSimpleRequestWrapperPortalMem.writeClient,cons\(lSimpleRequestProxyPortalMem.writeClient,nil\)\)

BSVFILES = Simple.bsv
#BSVFILES += Top.bsv
CPPFILES=testsimple.cpp $(CONNECTALDIR)/cpp/portalShared.c
AUTOTOP = --importfiles SharedMemoryPortal --importfiles SharedMemoryPortalConfig

include $(CONNECTALDIR)/Makefile.connectal
