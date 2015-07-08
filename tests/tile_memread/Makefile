
CONNECTALDIR?=../..
INTERFACES = ReadTestRequest ReadTestIndication
BSVFILES = ReadTest.bsv $(CONNECTALDIR)/bsv/PlatformTypes.bsv ReadTestEnum.bsv
CPPFILES=testmemread.cpp
NUMBER_OF_MASTERS = 1
# 1 tile for Platform, 1 tile for test itself
NUMBER_OF_TILES = 2

CONNECTALFLAGS += -P mkTile
# --floorplan=floorplan.xdc

include $(CONNECTALDIR)/Makefile.connectal
