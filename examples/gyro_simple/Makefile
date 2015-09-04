CONNECTALDIR ?= ../..
S2H_INTERFACES = GyroCtrlRequest:GyroController.req
H2S_INTERFACES = GyroController:GyroCtrlIndication
MEM_WRITE_INTERFACES = cons\(lGyroController.dmaClient,nil\)
INTERFACES = GyroSampleStream

AUTOTOP = --interface pins:GyroController.pins --portname IfcNames_GyroSampleStream
ZBR = $(CONNECTALDIR)/lib/zedboard_robot
BSVFILES = $(ZBR)/bsv/GyroController.bsv
CPPFILES = test_gyro.cpp $(ZBR)/cpp/read_buffer.cpp

PIN_TYPE = GyroSimplePins
PIN_TYPE_INCLUDE = GyroController
PINOUT_FILE = pinout.json
PIN_BINDINGS = pmod:pmodd

include $(CONNECTALDIR)/Makefile.connectal
