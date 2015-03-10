
CONNECTALDIR?=../..
INTERFACES = SimpleRequest MMURequest MMUIndication MemServerRequest MemServerIndication SharedMemoryPortalConfig
#INTERFACES = SharedMemoryPortalConfig
#S2H_INTERFACES = SimpleRequest:Simple.request
#H2S_INTERFACES = SimpleRequest:Simple
#MEM_INTERFACES = MemServer.request:/cons\(reqPortal.readClient,cons\(indPortal.readClient,nil\)\),cons\(reqPort

BSVFILES = Simple.bsv
BSVFILES += Top.bsv
CPPFILES=testsimple.cpp $(CONNECTALDIR)/cpp/portalShared.c
#AUTOTOP = --portname ReqConfigWrapper --portname IndConfigWrapper

include $(CONNECTALDIR)/Makefile.connectal
