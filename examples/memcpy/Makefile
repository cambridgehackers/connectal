
ifeq ($(BOARD),kc705)
TOP=PcieTop
endif
ifeq ($(BOARD),vc707)
TOP=PcieTop
endif
ifeq ($(BOARD),zedboard)
TOP=ZynqTop
endif
ifeq ($(BOARD),zc702)
TOP=ZynqTop
endif

BSVDIR=../../bsv

all:
	../../genxpsprojfrombsv -B $(BOARD) -p $(BOARD) -x mk$(TOP) -s2h MemcpyRequest -s2h BlueScopeRequest -s2h DMARequest -h2s MemcpyIndication -h2s BlueScopeIndication -h2s DMAIndication \
	-s testmemcpy.cpp  -t $(BSVDIR)/$(TOP).bsv -M implementation Memcpy.bsv $(BSVDIR)/BlueScope.bsv $(BSVDIR)/PortalMemory.bsv

