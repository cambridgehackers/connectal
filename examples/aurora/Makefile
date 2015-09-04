CONNECTALDIR?=../..
INTERFACES = AuroraRequest AuroraIndication

BSVFILES = Aurora.bsv Top.bsv
CPPFILES=testaurora.cpp
PIN_TYPE = AuroraPins
PIN_TYPE_INCLUDE = BviAurora
CONNECTALFLAGS += -C $(BOARD)/sources/aurora-$(BOARD).xdc -C aurora-clocks.xdc --tcl clock.tcl

AURORA_V = $(CONNECTALDIR)/generated/xilinx/$(BOARD)/aurora_64b66b_0/aurora_64b66b_0_stub.v

gentarget:: $(BOARD)/sources/aurora-$(BOARD).xdc

prebuild:: $(AURORA_V) BviAurora.bsv

$(AURORA_V): synth-ip.tcl
	(cd $(BOARD); vivado -mode batch -source ../synth-ip.tcl)

BviAurora.bsv:
	$(CONNECTALDIR)/generated/scripts/importbvi.py -o BviAurora.bsv -I BviAurora64  -P Au64 -n refclk1_in -n gt_qpllclk_quad2 -n gt_qpllrefclk_quad2 -c refclk1_in -r reset -c clk_in -c init_clk -c user_clk -c sync_clk $(AURORA_V)

$(BOARD)/sources/aurora-$(BOARD).xdc: aurora.json $(CONNECTALDIR)/boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
	$(CONNECTALDIR)/scripts/generate-constraints.py --boardfile $(CONNECTALDIR)/boardinfo/$(BOARD).json --pinoutfile aurora.json > $(BOARD)/sources/aurora-$(BOARD).xdc

include $(CONNECTALDIR)/Makefile.connectal
