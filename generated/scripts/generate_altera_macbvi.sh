#
#
set -x
set -e
./importbvi.py -o ALTERA_MAC_WRAPPER.bsv -I MacWrap -P MacWrap \
    -c p0_tx_clk_clk -c p1_tx_clk_clk -c p2_tx_clk_clk -c p3_tx_clk_clk \
    -c p0_rx_clk_clk -c p1_rx_clk_clk -c p2_rx_clk_clk -c p3_rx_clk_clk \
    -c mgmt_clk_clk \
    -r mgmt_reset_reset_n -r jtag_reset_reset \
    -r p0_tx_reset_reset_n -r p1_tx_reset_reset_n -r p2_tx_reset_reset_n -r p3_tx_reset_reset_n \
    -r p0_rx_reset_reset_n -r p1_rx_reset_reset_n -r p2_rx_reset_reset_n -r p3_rx_reset_reset_n \
    -f p0_tx -f p0_rx -f p1_tx -f p1_rx -f p2_tx -f p2_rx -f p3_tx -f p3_rx \
    -f p0_xgmii -f p1_xgmii -f p2_xgmii -f p3_xgmii \
    -f p0_link_fault -f p1_link_fault -f p2_link_fault -f p3_link_fault \
    ../../out/de5/synthesis/altera_mac.v

