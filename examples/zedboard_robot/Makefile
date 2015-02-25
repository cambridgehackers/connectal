
CONNECTALDIR ?= ../..
INTERFACES = MaxSonarCtrlRequest MaxSonarCtrlIndication GyroCtrlRequest GyroCtrlIndication
BSVFILES = Controller.bsv Top.bsv ../gyro_simple/GyroController.bsv ../maxsonar_simple/MaxSonarController.bsv
CPPFILES= test_zedboard_robot.cpp ../maxsonar_simple/maxsonar_simple.h ../gyro_simple/gyro_simple.h $(CONNECTALDIR)/cpp/sock_server.cpp
NUMBER_OF_MASTERS =1
PIN_TYPE = ZedboardRobotPins
CONNECTALFLAGS = -C $(BOARD)/sources/pinout-$(BOARD).xdc

PIN_BINDING ?= -b pmod_sonar:pmodb -b pmod_gyro:pmodd

gentarget:: $(BOARD)/sources/pinout-$(BOARD).xdc
$(BOARD)/sources/pinout-$(BOARD).xdc: pinout.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
	$(CONNECTALDIR)/scripts/generate-constraints.py $(PIN_BINDING) -o $(BOARD)/sources/pinout-$(BOARD).xdc $(CONNECTALDIR)/boardinfo/$(BOARD).json pinout.json

include $(CONNECTALDIR)/Makefile.connectal
