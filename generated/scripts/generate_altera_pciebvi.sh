#
#
set -x
set -e
./importbvi.py -o ALTERA_PCIE_WRAPPER.bsv -I PcieWrap -P PcieWrap \
    -r pin_perst -r npor -r reset_status \
    -c refclk -c pld_clk -c coreclkout_hip \
    -f serdes -f pld_clk -f pld_cor -f dl -f ev128 -f ev1 -f hotrst -f l2 -f current \
    -f derr -f lane -f ltssm -f reconfig \
    -f in -f aer -f pex -f serr -f cpl -f tl -f pm_e -f pme -f pm \
	-f tx_cred \
    -f tx_par -f rx_par -f cfg_par \
    -f tx \
    -f rx \
    -f eidle -f power -f phy \
    -f sim \
    -f test_in \
    ../../out/de5/synthesis/altera_pcie_sv_hip_ast.v

    #-f rxdata -f rxpolarity -f rx_in -f rxdatak -f rxelecidle -f rxstatus -f rxvalid \
    #-f txdata -f tx_cred -f tx_out -f txcompl -f txdatak -f txdetectrx -f txelecidle -f txdeemph -f txmargin -f txswing \

./importbvi.py -o ALTERA_PCIE_RECONFIG_DRIVER_WRAPPER.bsv -I PcieReconfigWrap -P PcieReconfigWrap \
  -c reconfig_xcvr_clk -c pld_clk -r reconfig_xcvr_rst \
  -f reconfig_mgmt -f reconfig_b -f current -f derr -f dlup -f ev128ns -f ev1us -f hotrst \
  -f int_status -f l2_exit -f lane_act -f ltssmstate -f dlup -f rx_par_err -f tx_par_err \
  -f cfg_par_err -f ko \
  ../../out/de5/synthesis/altera_pcie_reconfig_driver.v

./importbvi.py -o ALTERA_XCVR_RECONFIG_WRAPPER.bsv -I XcvrReconfigWrap -P XcvrReconfigWrap \
	-c mgmt_clk_clk -r mgmt_rst_reset \
      -f reconfig_mgmt -f reconfig -f mgmt \
      ../../out/de5/synthesis/alt_xcvr_reconfig.v

./importbvi.py -o ALTERA_PCIE_ED_WRAPPER.bsv -I PcieEdWrap -P PcieEdWrap \
	-c coreclkout_hip -c pld_clk_hip \
    -f serdes -f reset -f pld -f dl -f ev128 -f ev1 -f hotrst -f l2 -f current \
    -f derr -f lane -f ltssm -f reconfig \
    -f in -f aer -f pex -f serr -f cpl -f tl -f pm_e -f pme -f pm\
    -f tx_s -f rx_s \
	-f tx_cred \
    -f tx_par -f rx_par -f cfg_par \
    ../../out/de5/synthesis/altera_pcie_hip_ast_ed.v
