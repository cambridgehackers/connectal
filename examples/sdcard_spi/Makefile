
CONNECTALDIR?=../..

BSVFILES = SPITest.bsv
CPPFILES = sdcard_spi.cpp

S2H_INTERFACES = SPIRequest:SPITest.spiRequest
H2S_INTERFACES = SPITest:SPIIndication
MEM_READ_INTERFACES =
MEM_WRITE_INTERFACES =

PINOUT_FILE += pin_translation.json
PIN_TYPE = SPIMasterPins
PIN_TYPE_INCLUDE = SPI
AUTOTOP = --interface pins:SPITest.spiMasterPins

include $(CONNECTALDIR)/Makefile.connectal

