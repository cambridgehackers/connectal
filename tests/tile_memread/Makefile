
CONNECTALDIR?=../..
INTERFACES = MemreadRequest MemreadIndication
BSVFILES = Memread.bsv $(CONNECTALDIR)/bsv/PlatformTypes.bsv
CPPFILES=testmemread.cpp
NUMBER_OF_MASTERS = 1
NUMBER_OF_TILES = 1

CONNECTALFLAGS += -P mkTile --floorplan=floorplan.xdc

include $(CONNECTALDIR)/Makefile.connectal
