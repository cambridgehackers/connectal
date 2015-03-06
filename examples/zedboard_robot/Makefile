
CONNECTALDIR ?= ../..
ZBR_BSV = $(CONNECTALDIR)/lib/zedboard_robot/bsv
ZBR_CPP = $(CONNECTALDIR)/lib/zedboard_robot/cpp
INTERFACES = MaxSonarCtrlRequest MaxSonarCtrlIndication GyroCtrlRequest GyroCtrlIndication HBridgeCtrlRequest HBridgeCtrlIndication GyroSampleStream MaxSonarSampleStream
BSVFILES = Controller.bsv Top.bsv $(ZBR_BSV)/GyroController.bsv $(ZBR_BSV)/MaxSonarController.bsv $(ZBR_BSV)/HBridgeController.bsv
CPPFILES= test_zedboard_robot.cpp ../maxsonar_simple/maxsonar_simple.h ../hbridge_simple/hbridge_simple.h ../gyro_simple/gyro_simple.h $(ZBR_CPP)/read_buffer.cpp
NUMBER_OF_MASTERS =1
PIN_TYPE = ZedboardRobotPins
CONNECTALFLAGS = -C $(BOARD)/sources/pinout-$(BOARD).xdc

PIN_BINDING ?= -b pmod_sonar:pmodb -b pmod_gyro:pmodd -b pmod_hbridge:pmodc

gentarget:: $(BOARD)/sources/pinout-$(BOARD).xdc
$(BOARD)/sources/pinout-$(BOARD).xdc: pinout.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
	$(CONNECTALDIR)/scripts/generate-constraints.py $(PIN_BINDING) -o $(BOARD)/sources/pinout-$(BOARD).xdc $(CONNECTALDIR)/boardinfo/$(BOARD).json pinout.json

include $(CONNECTALDIR)/Makefile.connectal
