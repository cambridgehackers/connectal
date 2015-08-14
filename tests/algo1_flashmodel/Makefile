
CONNECTALDIR?=../..
INTERFACES = StrstrRequest StrstrIndication FlashRequest FlashIndication
BSVFILES = $(CONNECTALDIR)/lib/strstr/bsv/Strstr.bsv $(CONNECTALDIR)/lib/nandsim/bsv/NandSimNames.bsv Top.bsv FlashTop.bsv
#CPPFILES2=$(CONNECTALDIR)/examples/algo1_nandsim/test.cpp
CPPFILES=test.cpp
CONNECTALFLAGS += -D DEGPAR=2
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/strstr/cpp
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/nandsim/cpp
PIN_TYPE = Top_Pins
PIN_TYPE_INCLUDE = TopPins
CONNECTALFLAGS += -D IMPORT_HOSTIF --bscflags " -D DataBusWidth=128 " --clib rt
include $(CONNECTALDIR)/Makefile.connectal

# #Note: for some reason, xbsv can't parase ControllerTypes.bsv properly. So a soft link in current directory is created
# BSVFILES = Main.bsv Top.bsv \
# 	../../xilinx/aurora_8b10b_fmc1/AuroraImportFmc1.bsv \
# 	../../src/lib/AuroraCommon.bsv \
# 	../../controller/src/common/FlashBusModel.bsv \
# 	../../controller/src/model_virtex/FlashCtrlModel.bsv \
# 	../../controller/src/hw_virtex/FlashCtrlVirtex.bsv

# CPPFILES=main.cpp
# #CONNECTALFLAGS=--bscflags " -D TRACE_AXI"




# ifeq ($(BOARD), vc707)
# CONNECTALFLAGS += \
# 	--verilog ../../xilinx/aurora_8b10b_fmc1/ \
# 	--xci $(CONNECTALDIR)/out/$(BOARD)/aurora_8b10b_fmc1/aurora_8b10b_fmc1.xci \
# 	--constraint ../../xilinx/aurora_8b10b_fmc1/aurora_8b10b_fmc1_exdes.xdc 

# 	#--verilog ../../../xbsv/xilinx/ddr3_v1_7/ \
# 	--constraint ../../xilinx/ddr3_v2_0/vc707_ddr3_sx.xdc \
# 	--constraint $(CONNECTALDIR)/xilinx/constraints/vc707_ddr3.xdc \
# 	--verilog $(BLUESPECDIR)/board_support/bluenoc/xilinx/VC707/verilog/ddr3_v2_0/ddr3_v2_0/user_design/rtl/ \
# 	--verilog $(BLUESPECDIR)/board_support/bluenoc/xilinx/VC707/verilog/ddr3_v2_0/ddr3_v2_0/user_design/rtl/clocking \
# 	--verilog $(BLUESPECDIR)/board_support/bluenoc/xilinx/VC707/verilog/ddr3_v2_0/ddr3_v2_0/user_design/rtl/controller \
# 	--verilog $(BLUESPECDIR)/board_support/bluenoc/xilinx/VC707/verilog/ddr3_v2_0/ddr3_v2_0/user_design/rtl/ecc \
# 	--verilog $(BLUESPECDIR)/board_support/bluenoc/xilinx/VC707/verilog/ddr3_v2_0/ddr3_v2_0/user_design/rtl/ip_top \
# 	--verilog $(BLUESPECDIR)/board_support/bluenoc/xilinx/VC707/verilog/ddr3_v2_0/ddr3_v2_0/user_design/rtl/phy \
# 	--verilog $(BLUESPECDIR)/board_support/bluenoc/xilinx/VC707/verilog/ddr3_v2_0/ddr3_v2_0/user_design/rtl/ui \
# AURORA_INTRA = $(CONNECTALDIR)/out/$(BOARD)/aurora_8b10b_fmc1/aurora_8b10b_fmc1_stub.v
# prebuild:: $(AURORA_INTRA)

# $(AURORA_INTRA): core-scripts/synth-aurora-intra.tcl
# 	(cd $(BOARD); vivado -mode batch -source ../core-scripts/synth-aurora-intra.tcl)
# endif

# include $(CONNECTALDIR)/Makefile.connectal
