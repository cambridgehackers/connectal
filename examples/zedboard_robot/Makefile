CONNECTALDIR ?= ../..
S2H_INTERFACES += MaxSonarCtrlRequest:Controller.maxsonar_req
S2H_INTERFACES += HBridgeCtrlRequest:Controller.hbridge_req
S2H_INTERFACES += GyroCtrlRequest:Controller.gyro_req
H2S_INTERFACES = Controller:MaxSonarCtrlIndication,GyroCtrlIndication,HBridgeCtrlIndication

MEM_WRITE_INTERFACES = cons\(lController.dmaClient,nil\)
INTERFACES += GyroSampleStream MaxSonarSampleStream

ZBR = $(CONNECTALDIR)/lib/zedboard_robot
BSVFILES = Controller.bsv $(ZBR)/bsv/GyroController.bsv $(ZBR)/bsv/MaxSonarController.bsv $(ZBR)/bsv/HBridgeController.bsv
CPPFILES= test_zedboard_robot.cpp ../maxsonar_simple/maxsonar_simple.h ../hbridge_simple/hbridge_simple.h ../gyro_simple/gyro_simple.h $(ZBR)/cpp/read_buffer.cpp

PIN_TYPE = ZedboardRobotPins
PIN_TYPE_INCLUDE = Controller
PINOUT_FILE = pinout.json
PIN_BINDINGS ?= pmod_sonar:pmodb pmod_gyro:pmodd pmod_hbridge:pmodc
AUTOTOP = --interface pins:Controller.pins --portname IfcNames_GyroSampleStream --portname IfcNames_MaxSonarSampleStream

include $(CONNECTALDIR)/Makefile.connectal
