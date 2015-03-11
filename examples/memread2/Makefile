
CONNECTALDIR?=../..
S2H_INTERFACES = Memread2Request:Memread2.request
H2S_INTERFACES = Memread2:Memread2Indication
MEM_INTERFACES = cons\(lMemread2.dmaClient0,cons\(lMemread2.dmaClient1,nil\)\),nil
BSVFILES = Memread2.bsv
# $(CONNECTALDIR)/lib/deprecated/DmaUtils.bsv
CPPFILES=testmemread2.cpp

include $(CONNECTALDIR)/Makefile.connectal
