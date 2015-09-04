CONNECTALDIR ?= ../..
S2H_INTERFACES = MaxSonarCtrlRequest:MaxSonarController.req
H2S_INTERFACES = MaxSonarController:MaxSonarCtrlIndication

ZBR = $(CONNECTALDIR)/lib/zedboard_robot
BSVFILES = $(ZBR)/bsv/MaxSonarController.bsv
CPPFILES= test_maxsonar.cpp $(ZBR)/cpp/read_buffer.cpp
AUTOTOP = --interface pins:MaxSonarController.pins

PIN_TYPE = MaxSonarSimplePins
PIN_TYPE_INCLUDE = MaxSonarController
PINOUT_FILE = pinout.json
PIN_BINDINGS = pmod:pmodb

include $(CONNECTALDIR)/Makefile.connectal
