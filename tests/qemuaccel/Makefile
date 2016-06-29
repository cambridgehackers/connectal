CONNECTALDIR?=../..

INTERFACES = SimpleRequest UartRequest UartIndication

S2H_INTERFACES = QemuAccelRequest:QemuAccel.request MemServerPortalRequest:QemuAccel.memServerPortalRequest
H2S_INTERFACES = QemuAccel:QemuAccelIndication,MemServerPortalResponse

#MEM_READ_INTERFACES = lQemuAccel.dmaReadClient
#MEM_WRITE_INTERFACES = lQemuAccel.dmaWriteClient

BSVFILES = $(CONNECTALDIR)/bsv/ConnectalConfig.bsv  $(CONNECTALDIR)/examples/simple/Simple.bsv $(CONNECTALDIR)/bsv/MemServerPortal.bsv AccelIfcNames.bsv QemuAccelIfc.bsv Uart.bsv
CPPFILES = $(CONNECTALDIR)/lib/qemu/fpgadev.cpp

CONNECTALFLAGS += --bsvpath $(CONNECTALDIR)/examples/simple
CONNECTALFLAGS += --shared

prebuild::
	$(CONNECTALDIR)/scripts/topgen.py --project-dir . --filename 'AccelTop.bsv' --ifcnames 'AccelIfcNames' --wrapper UartRequest:Uart.request --wrapper SimpleRequest:Simple.request --proxy Uart:UartIndication --proxy Simple:SimpleRequest

include $(CONNECTALDIR)/Makefile.connectal

