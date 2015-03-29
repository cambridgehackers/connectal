
CONNECTALDIR ?= ../..
ZBR_BSV = $(CONNECTALDIR)/lib/zedboard_robot/bsv
ZBR_CPP = $(CONNECTALDIR)/lib/zedboard_robot/cpp
INTERFACES = GyroCtrlRequest GyroCtrlIndication GyroSampleStream
BSVFILES = $(ZBR_BSV)/GyroController.bsv Top.bsv
CPPFILES = test_gyro.cpp $(ZBR_CPP)/read_buffer.cpp
NUMBER_OF_MASTERS = 1

PIN_TYPE = GyroSimplePins
PINOUT_FILE = pinout.json
PIN_BINDINGS = pmod:pmodd

include $(CONNECTALDIR)/Makefile.connectal
