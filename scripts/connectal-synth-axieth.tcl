source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

set prj_boardname $boardname
if [string match "*g2" $boardname] {set prj_boardname [string trimright $boardname "g2"]}

connectal_synth_ip axi_ethernet 7.0 axi_ethernet_0 [list CONFIG.ETHERNET_BOARD_INTERFACE {sfp_sfp1} CONFIG.DIFFCLK_BOARD_INTERFACE {sfp_mgt_clk} CONFIG.axiliteclkrate {250.0} CONFIG.axisclkrate {250.0} CONFIG.PHY_TYPE {1000BaseX}]

