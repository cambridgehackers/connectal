CONNECTALDIR ?= ../..
S2H_INTERFACES = MaxSonarCtrlRequest:MaxSonarController.req
H2S_INTERFACES = MaxSonarController:MaxSonarCtrlIndication

ZBR = $(CONNECTALDIR)/lib/zedboard_robot
BSVFILES = $(ZBR)/bsv/MaxSonarController.bsv
CPPFILES= test_maxsonar.cpp $(ZBR)/cpp/read_buffer.cpp
NUMBER_OF_MASTERS=0
AUTOTOP = --interface pins:MaxSonarController.pins --importfiles MaxSonarController

PIN_TYPE = MaxSonarSimplePins
PINOUT_FILE = pinout.json
PIN_BINDINGS = pmod:pmodb

include $(CONNECTALDIR)/Makefile.connectal
