#
#
set -x
set -e
#./importbvi.py -o ALTERA_PCIE_SV_WRAPPER.bsv -I PcieWrap -P PcieWrap \
#    -r pin_perst -r npor -r reset_status \
#    -c refclk -c coreclkout_hip \
#    -f serdes -f pld -f dl -f ev128 -f ev1 -f hotrst -f l2 -f current \
#    -f derr -f lane -f ltssm -f reconfig \
#    -f tx_cred -f tx_par -f tx_s -f txd -f txe -f txc -f txm -f txs -f tx\
#    -f tx_cred -f rx_par -f rx_s -f rxd -f rxr -f rxe -f rxp -f rxs -f rxv -f rx\
#	-f cfg_par \
#    -f eidle -f power -f phy \
#    -f int_s -f cpl -f tl -f pm_e -f pme -f pm \
#    -f simu -f sim \
#    -f test_in \
#    ../../out/de5/synthesis/altera_pcie_sv_hip_ast_wrapper.v
#
#    #-f rxdata -f rxpolarity -f rxdatak -f rxelecidle -f rxstatus -f rxvalid \
#    #-f txdata -f tx_cred -f tx_out -f txcompl -f txdatak -f txdetectrx -f txelecidle -f txdeemph -f txmargin -f txswing \
#
#./importbvi.py -o ALTERA_PCIE_RECONFIG_DRIVER_WRAPPER.bsv -I PcieReconfigWrap -P PcieReconfigWrap \
#  -c reconfig_xcvr_clk -c pld_clk -r reconfig_xcvr_rst \
#  -f reconfig_mgmt -f reconfig_b -f current -f derr -f dlup -f ev128ns -f ev1us -f hotrst \
#  -f int_s -f l2 -f lane -f ltssmstate -f dlup -f rx -f tx \
#  -f tx -f rx -f cfg -f ko \
#  ../../out/de5/synthesis/altera_pcie_reconfig_driver_wrapper.v
#
#./importbvi.py -o ALTERA_XCVR_RECONFIG_WRAPPER.bsv -I XcvrReconfigWrap -P XcvrReconfigWrap \
#	-c mgmt_clk_clk -r mgmt_rst_reset \
#      -f reconfig_mgmt -f mgmt \
#      ../../out/de5/synthesis/alt_xcvr_reconfig_wrapper.v

#./importbvi.py -o ALTERA_PCIE_ED_WRAPPER.bsv -I PcieEdWrap -P PcieEdWrap \
#	-c coreclkout_hip -c pld_clk_hip \
#    -f serdes -f reset -f pld -f dl -f ev128 -f ev1 -f hotrst -f l2 -f current \
#    -f derr -f lane -f ltssm -f reconfig \
#    -f int_s -f aer -f pex -f serr -f cpl -f tl -f pm_e -f pme -f pm\
#    -f tx_s -f rx_s \
#	-f tx_cred \
#    -f tx_par -f rx_par -f cfg_par \
#    ../../out/de5/synthesis/altera_pcie_hip_ast_ed.v

#./importbvi.py -o ALTERA_PLL_WRAPPER.bsv -I PciePllWrap -P PciePllWrap \
#    -c refclk -r rst \
#    -f out -f locked \
#    ../../out/de5/synthesis/altera_pll_wrapper.v

./importbvi.py -o ALTERA_PCIE_SIV_WRAPPER.bsv -I PcieS4Wrap -P PcieS4Wrap \
    -r pin_perst -r npor -r reset_status -r pcie_rstn -r srstn \
    -c refclk -c core_clk_out -c reconfig_clk -c fixedclk_serdes \
	-f app -f pex_msi \
	-f cpl \
	-f pclk_in \
	-f clk250_out \
	-f clk500_out \
	-f rx_st \
	-f tx_st \
	-f fixedclk \
	-f lmi \
    -f tx \
    -f rx \
	-f phystatus \
	-f pipe \
	-f pm \
	-f pme \
	-f reconfig \
	-f test \
	-f lane \
	-f ltssm \
	-f powerdown \
	-f rate \
	-f rc_pll \
	-f tl_cfg \
    ../../out/htg4/siv_gen2x8/siv_gen2x8_examples/chaining_dma/siv_gen2x8_plus.v
