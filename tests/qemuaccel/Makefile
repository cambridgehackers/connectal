CONNECTALDIR?=../..

INTERFACES = SimpleRequest

S2H_INTERFACES = QemuAccelRequest:QemuAccel.request MemServerPortalRequest:QemuAccel.memServerPortalRequest
H2S_INTERFACES = QemuAccel:QemuAccelIndication,MemServerPortalResponse

#MEM_READ_INTERFACES = lQemuAccel.dmaReadClient
#MEM_WRITE_INTERFACES = lQemuAccel.dmaWriteClient

BSVFILES = $(CONNECTALDIR)/bsv/ConnectalConfig.bsv  $(CONNECTALDIR)/examples/simple/Simple.bsv $(CONNECTALDIR)/bsv/MemServerPortal.bsv AccelIfcNames.bsv QemuAccelIfc.bsv
CPPFILES = qemuaccel.cpp

CONNECTALFLAGS += --bsvpath $(CONNECTALDIR)/examples/simple

prebuild::
	$(CONNECTALDIR)/scripts/topgen.py --project-dir . --filename 'AccelTop.bsv' --ifcnames 'AccelIfcNames' --importfiles Simple --wrapper SimpleRequest:Simple.request --proxy Simple:SimpleRequest

include $(CONNECTALDIR)/Makefile.connectal

