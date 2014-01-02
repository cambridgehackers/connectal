
ifeq ($(BOARD),kc705)
TOP=PcieTop
endif
ifeq ($(BOARD),vc707)
TOP=PcieTop
endif
ifeq ($(BOARD),zedboard)
TOP=ZynqTop
endif
ifeq ($(BOARD),zc702)
TOP=ZynqTop
endif

all:
	../../genxpsprojfrombsv -B$(BOARD) -p $(BOARD) -x mk$(TOP) -s2h Swallow -s2h EchoRequest -h2s EchoIndication \
	-s testecho.cpp -t ../../bsv/$(TOP).bsv -M verilog -M implementation Echo.bsv Swallow.bsv

