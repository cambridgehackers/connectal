
CONNECTALDIR ?= ../..
ZBR_BSV = $(CONNECTALDIR)/lib/zedboard_robot/bsv
ZBR_CPP = $(CONNECTALDIR)/lib/zedboard_robot/cpp
INTERFACES = MaxSonarCtrlRequest MaxSonarCtrlIndication GyroCtrlRequest GyroCtrlIndication HBridgeCtrlRequest HBridgeCtrlIndication GyroSampleStream MaxSonarSampleStream
BSVFILES = Controller.bsv Top.bsv $(ZBR_BSV)/GyroController.bsv $(ZBR_BSV)/MaxSonarController.bsv $(ZBR_BSV)/HBridgeController.bsv
CPPFILES= test_zedboard_robot.cpp ../maxsonar_simple/maxsonar_simple.h ../hbridge_simple/hbridge_simple.h ../gyro_simple/gyro_simple.h $(ZBR_CPP)/read_buffer.cpp
NUMBER_OF_MASTERS =1

PIN_TYPE = ZedboardRobotPins
PINOUT_FILE = pinout.json
PIN_BINDINGS ?= pmod_sonar:pmodb pmod_gyro:pmodd pmod_hbridge:pmodc

include $(CONNECTALDIR)/Makefile.connectal
