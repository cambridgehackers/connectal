CONNECTALDIR?=../..

INTERFACES = SimpleRequest SerialRequest SerialIndication

S2H_INTERFACES = QemuAccelRequest:QemuAccel.request MemServerPortalRequest:QemuAccel.memServerPortalRequest SerialRequest:QemuAccel.uartRequest
H2S_INTERFACES = QemuAccel:QemuAccelIndication,MemServerPortalResponse,SerialIndication

#MEM_READ_INTERFACES = lQemuAccel.dmaReadClient
#MEM_WRITE_INTERFACES = lQemuAccel.dmaWriteClient

BSVFILES = $(CONNECTALDIR)/bsv/ConnectalConfig.bsv  $(CONNECTALDIR)/examples/simple/Simple.bsv $(CONNECTALDIR)/bsv/MemServerPortal.bsv AccelIfcNames.bsv QemuAccelIfc.bsv Serial.bsv
CPPFILES = $(CONNECTALDIR)/lib/qemu/fpgadev.cpp

CONNECTALFLAGS += --bsvpath $(CONNECTALDIR)/examples/simple
CONNECTALFLAGS += --shared

prebuild::
	$(CONNECTALDIR)/scripts/topgen.py --project-dir . --filename 'AccelTop.bsv' --ifcnames 'AccelIfcNames' --wrapper SerialRequest:Serial.request --wrapper SimpleRequest:Simple.request --proxy Serial:SerialIndication --proxy Simple:SimpleRequest --interface pins:Serial.port --pintype SerialPort

include $(CONNECTALDIR)/Makefile.connectal

