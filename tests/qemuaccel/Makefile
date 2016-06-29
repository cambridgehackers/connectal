CONNECTALDIR?=../..

INTERFACES = SimpleRequest SerialRequest SerialIndication BlockDevRequest BlockDevResponse

S2H_INTERFACES = QemuAccelRequest:QemuAccel.request MemServerPortalRequest:QemuAccel.memServerPortalRequest SerialRequest:QemuAccel.uartRequest BlockDevResponse:QemuAccel.blockDevResponse
H2S_INTERFACES = QemuAccel:QemuAccelIndication,MemServerPortalResponse,SerialIndication,BlockDevRequest

#MEM_READ_INTERFACES = lQemuAccel.dmaReadClient
#MEM_WRITE_INTERFACES = lQemuAccel.dmaWriteClient

BSVFILES = $(CONNECTALDIR)/bsv/ConnectalConfig.bsv  $(CONNECTALDIR)/examples/simple/Simple.bsv $(CONNECTALDIR)/bsv/MemServerPortal.bsv AccelIfcNames.bsv QemuAccelIfc.bsv Serial.bsv BlockDev.bsv
CPPFILES = $(CONNECTALDIR)/lib/qemu/fpgadev.cpp

CONNECTALFLAGS += --bsvpath $(CONNECTALDIR)/examples/simple
CONNECTALFLAGS += --shared

prebuild::
	$(CONNECTALDIR)/scripts/topgen.py --project-dir . --filename 'AccelTop.bsv' --ifcnames 'AccelIfcNames' --wrapper SerialRequest:Serial.request --wrapper SimpleRequest:Simple.request --proxy Serial:SerialIndication --proxy Simple:SimpleRequest --interface pins:Serial.port --wrapper BlockDevRequest:BlockDev.request --proxy BlockDev:BlockDevResponse --pintype 'SerialPort'

include $(CONNECTALDIR)/Makefile.connectal

