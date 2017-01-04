
CONNECTALDIR?=../..

S2H_INTERFACES = NandCfgRequest:Algo1NandSim.nandCfgRequest MMURequest:Algo1NandSim.nandMMURequest MemServerRequest:Algo1NandSim.nandMemServerRequest StrstrRequest:Algo1NandSim.strstrRequest
H2S_INTERFACES = Algo1NandSim:NandCfgIndication,MMUIndication,MemServerIndication,StrstrIndication
MEM_READ_INTERFACES = lAlgo1NandSim.dmaReadClients
MEM_WRITE_INTERFACES = lAlgo1NandSim.dmaWriteClients

BSVFILES = $(CONNECTALDIR)/lib/nandsim/bsv/NandSim.bsv $(CONNECTALDIR)/lib/strstr/bsv/Strstr.bsv Algo1NandSim.bsv
CPPFILES=test.cpp nandsim.cpp

CONNECTALFLAGS += -D ALGO_NANDSIM
CONNECTALFLAGS += -D DEGPAR=2
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/strstr/cpp
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/nandsim/cpp


include $(CONNECTALDIR)/Makefile.connectal
