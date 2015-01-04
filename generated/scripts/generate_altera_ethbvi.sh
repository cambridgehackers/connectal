#
#
set -x
set -e
./importbvi.py -o ALTERA_ETH_PMA_WRAPPER.bsv -I EthXcvrWrap -P EthXcvrWrap \
    -c rx_pma_clkout -c tx_pma_clkout -c tx_pll_refclk -c rx_cdr_refclk \
    -f pll -f tx -f rx -f reconfig \
    ../../out/de5/synthesis/altera_xcvr_native_sv_wrapper.v

./importbvi.py -o ALTERA_ETH_PMA_RECONFIG_WRAPPER.bsv -I EthXcvrReconfigWrap -P EthXcvrReconfigWrap \
  -c mgmt_clk_clk -r mgmt_rst_reset \
  -f reconfig \
  ../../out/de5/synthesis/altera_xgbe_pma_reconfig_wrapper.v

./importbvi.py -o ALTERA_ETH_PMA_RESET_CONTROL_WRAPPER.bsv -I EthXcvrResetWrap -P EthXcvrResetWrap \
	-c clock -r reset \
    -f pll -f tx -f rx \
    ../../out/de5/synthesis/altera_xcvr_reset_control_wrapper.v

