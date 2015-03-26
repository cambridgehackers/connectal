
CONNECTALDIR ?= ../..
ZBR_BSV = $(CONNECTALDIR)/lib/zedboard_robot/bsv
ZBR_CPP = $(CONNECTALDIR)/lib/zedboard_robot/cpp
INTERFACES = MaxSonarCtrlRequest MaxSonarCtrlIndication
BSVFILES = $(ZBR_BSV)/MaxSonarController.bsv Top.bsv 
CPPFILES= test_maxsonar.cpp $(ZBR_CPP)/read_buffer.cpp
NUMBER_OF_MASTERS =1

PIN_TYPE = MaxSonarPins
PINOUT_FILE = pinout.json
PIN_BINDINGS = pmod:pmodb

include $(CONNECTALDIR)/Makefile.connectal
