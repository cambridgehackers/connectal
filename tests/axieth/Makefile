CONNECTALDIR?=../..
S2H_INTERFACES = AxiEthTestRequest:AxiEth.request
H2S_INTERFACES = AxiEth:AxiEthTestIndication:host
#MEM_READ_INTERFACES = lAxiEth.dmaReadClient
#MEM_WRITE_INTERFACES = lAxiEth.dmaWriteClient

CONNECTALFLAGS+= -P mkConnectalTop
CONNECTALFLAGS+= --shared


BSVFILES = AxiEth.bsv
CPPFILES=testaxieth.cpp

CONNECTALFLAGS+= -DDataBusWidth=32
## ethernet uses the 200MHz SYS clock
CONNECTALFLAGS += -D XILINX_SYS_CLK -D IMPORT_HOSTIF
CONNECTALFLAGS+= --xci=$(IPDIR)/$(BOARD)/axi_intc_0/axi_intc_0.xci
CONNECTALFLAGS+= --xci=$(IPDIR)/$(BOARD)/axi_dma_0/axi_dma_0.xci
CONNECTALFLAGS+= --xci=$(IPDIR)/$(BOARD)/axi_ethernet_0/axi_ethernet_0.xci
CONNECTALFLAGS += --constraint=axieth.xdc --implconstraint=axieth.xdc

ifeq ($(BOARD),vc709)
PINOUT_FILE += axieth.json
PIN_TYPE = AxiEthPins
PIN_TYPE_INCLUDE = EthPins
AUTOTOP = --interface pins:AxiEth.pins
endif

ifeq ($(BOARD),xsim)
AXI_ETH_DIR=/home/jamey/connectal/out/vc709/axi_ethernet_0
AXI_ETH_FILES=\
bd_0/ip/ip_0/fifo_generator_v13_0_1/simulation/fifo_generator_vhdl_beh.vhd \
bd_0/ip/ip_0/fifo_generator_v13_0_1/hdl/fifo_generator_v13_0_rfs.vhd \
bd_0/ip/ip_0/blk_mem_gen_v8_3_1/simulation/blk_mem_gen_v8_3.vhd \
bd_0/ip/ip_0/lib_bmg_v1_0_3/hdl/src/vhdl/blk_mem_gen_wrapper.vhd \
bd_0/ip/ip_0/axi_lite_ipif_v3_0_3/hdl/src/vhdl/ipif_pkg.vhd \
bd_0/ip/ip_0/axi_lite_ipif_v3_0_3/hdl/src/vhdl/pselect_f.vhd \
bd_0/ip/ip_0/axi_lite_ipif_v3_0_3/hdl/src/vhdl/address_decoder.vhd \
bd_0/ip/ip_0/axi_lite_ipif_v3_0_3/hdl/src/vhdl/slave_attachment.vhd \
bd_0/ip/ip_0/axi_lite_ipif_v3_0_3/hdl/src/vhdl/axi_lite_ipif.vhd \
bd_0/ip/ip_0/axi_ethernet_buffer_v2_0_10/hdl/axi_ethernet_buffer_v2_0_vh_rfs.vhd \
bd_0/ip/ip_0/sim/bd_0_eth_buf_0.vhd \
bd_0/ip/ip_1/xbip_utils_v3_0_5/hdl/xbip_utils_v3_0_vh_rfs.vhd \
bd_0/ip/ip_1/xbip_pipe_v3_0_1/hdl/xbip_pipe_v3_0_vh_rfs.vhd \
bd_0/ip/ip_1/xbip_pipe_v3_0_1/hdl/xbip_pipe_v3_0.vhd \
bd_0/ip/ip_1/xbip_bram18k_v3_0_1/hdl/xbip_bram18k_v3_0_vh_rfs.vhd \
bd_0/ip/ip_1/xbip_bram18k_v3_0_1/hdl/xbip_bram18k_v3_0.vhd \
bd_0/ip/ip_1/mult_gen_v12_0_10/hdl/mult_gen_v12_0_vh_rfs.vhd \
bd_0/ip/ip_1/mult_gen_v12_0_10/hdl/mult_gen_v12_0.vhd \
bd_0/ip/ip_1/tri_mode_ethernet_mac_v9_0_3/hdl/tri_mode_ethernet_mac_v9_0_rfs.v \
bd_0/ip/ip_1/tri_mode_ethernet_mac_v9_0_3/hdl/tri_mode_ethernet_mac_v9_0_rfs.vhd \
bd_0/ip/ip_1/synth/axi_ipif/bd_0_eth_mac_0_axi4_lite_ipif_top.vhd \
bd_0/ip/ip_1/synth/axi_ipif/bd_0_eth_mac_0_axi4_lite_ipif_wrapper.v \
bd_0/ip/ip_1/synth/statistics/bd_0_eth_mac_0_vector_decode.v \
bd_0/ip/ip_1/synth/bd_0_eth_mac_0_block.v \
bd_0/ip/ip_1/synth/bd_0_eth_mac_0.v \
bd_0/ip/ip_2/gig_ethernet_pcs_pma_v15_1_1/hdl/gig_ethernet_pcs_pma_v15_1_rfs.vhd \
bd_0/ip/ip_2/synth/bd_0_pcs_pma_0_resets.v \
bd_0/ip/ip_2/synth/bd_0_pcs_pma_0_clocking.v \
bd_0/ip/ip_2/synth/bd_0_pcs_pma_0_support.v \
bd_0/ip/ip_2/synth/bd_0_pcs_pma_0_gt_common.v \
bd_0/ip/ip_2/synth/transceiver/bd_0_pcs_pma_0_cpll_railing.v \
bd_0/ip/ip_2/synth/transceiver/bd_0_pcs_pma_0_gtwizard_gtrxreset_seq.v \
bd_0/ip/ip_2/synth/transceiver/bd_0_pcs_pma_0_gtwizard_gtrxpmarst_seq.v \
bd_0/ip/ip_2/synth/transceiver/bd_0_pcs_pma_0_gtwizard_init.v \
bd_0/ip/ip_2/synth/transceiver/bd_0_pcs_pma_0_tx_startup_fsm.v \
bd_0/ip/ip_2/synth/transceiver/bd_0_pcs_pma_0_rx_startup_fsm.v \
bd_0/ip/ip_2/synth/transceiver/bd_0_pcs_pma_0_reset_wtd_timer.v \
bd_0/ip/ip_2/synth/transceiver/bd_0_pcs_pma_0_gtwizard.v \
bd_0/ip/ip_2/synth/transceiver/bd_0_pcs_pma_0_gtwizard_multi_gt.v \
bd_0/ip/ip_2/synth/transceiver/bd_0_pcs_pma_0_gtwizard_gt.v \
bd_0/ip/ip_2/synth/bd_0_pcs_pma_0_reset_sync.v \
bd_0/ip/ip_2/synth/bd_0_pcs_pma_0_sync_block.v \
bd_0/ip/ip_2/synth/transceiver/bd_0_pcs_pma_0_transceiver.v \
bd_0/ip/ip_2/synth/bd_0_pcs_pma_0_block.v \
bd_0/ip/ip_2/synth/bd_0_pcs_pma_0.v \
bd_0/hdl/bd_0.v \
sim/axi_ethernet_0.v
CONNECTALFLAGS += $(addprefix --verilog=$(AXI_ETH_DIR)/, $(AXI_ETH_FILES))
endif

include $(CONNECTALDIR)/Makefile.connectal
