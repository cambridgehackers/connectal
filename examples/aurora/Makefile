
XBSVDIR=../..
BSVDIR=../../bsv
S2H = AuroraRequest
H2S = AuroraIndication
BSVFILES = Aurora.bsv Top.bsv
CPPFILES=testaurora.cpp
XBSVFLAGS +=  -D NumberOfMasters=0 -D PinType=AuroraPins
XBSVFLAGS += -C $(BOARD)/sources/aurora-$(BOARD).xdc -C aurora-clocks.xdc --tcl clock.tcl

AURORA_V = $(XBSVDIR)/generated/xilinx/$(BOARD)/aurora_64b66b_0/aurora_64b66b_0_stub.v

gentarget:: $(BOARD)/sources/aurora-$(BOARD).xdc

gentarget:: $(AURORA_V) BviAurora.bsv

$(AURORA_V): synth-ip.tcl
	(cd $(BOARD); vivado -mode batch -source ../synth-ip.tcl)

BviAurora.bsv:
	$(XBSVDIR)/generated/scripts/importbvi.py -o BviAurora.bsv -I BviAurora64  -P Au64 -n refclk1_in -n gt_qpllclk_quad2 -n gt_qpllrefclk_quad2 -c refclk1_in -r reset -c clk_in -c init_clk -c user_clk -c sync_clk $(AURORA_V)

$(BOARD)/sources/aurora-$(BOARD).xdc: aurora.json $(XBSVDIR)/boardinfo/$(BOARD).json
	mkdir -p $(BOARD)/sources
	$(XBSVDIR)/scripts/generate-constraints.py $(XBSVDIR)/boardinfo/$(BOARD).json aurora.json > $(BOARD)/sources/aurora-$(BOARD).xdc

include $(XBSVDIR)/Makefile.common
